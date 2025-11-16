#!/usr/bin/env node
/**
 * Cloudflare Bypass Proxy Server
 * Sử dụng Puppeteer + Chrome để bypass Cloudflare challenge
 * 
 * Flow: Mem0 → localhost:3000 → Chrome → langhit.com
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');
const puppeteer = require('puppeteer');

const PROXY_PORT = process.env.PROXY_PORT || 3000;
const TARGET_URL = process.env.TARGET_URL || 'https://langhit.com';

let browser = null;
let page = null;
let cfCookies = null;
let lastCookieUpdate = 0;
const COOKIE_REFRESH_INTERVAL = 30 * 60 * 1000; // 30 phút

/**
 * Khởi tạo Puppeteer browser
 */
async function initBrowser() {
    if (browser) {
        return browser;
    }

    console.log('[PROXY] Initializing Puppeteer browser...');
    browser = await puppeteer.launch({
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--disable-gpu',
            '--window-size=1920x1080',
        ],
    });

    page = await browser.newPage();
    
    // Set User-Agent giống browser thật
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    // Listen to console messages from page
    page.on('console', msg => {
        const text = msg.text();
        if (text.includes('[BROWSER]')) {
            console.log(text);
        }
    });
    
    // Navigate để lấy cookies
    await refreshCookies();
    
    console.log('[PROXY] Browser initialized');
    return browser;
}

/**
 * Refresh Cloudflare cookies
 */
async function refreshCookies() {
    try {
        console.log('[PROXY] Refreshing Cloudflare cookies...');
        
        // Navigate đến root URL trước để lấy cookies
        console.log(`[PROXY] Step 1: Navigating to root: ${TARGET_URL}`);
        await page.goto(TARGET_URL, {
            waitUntil: 'networkidle2',
            timeout: 60000,
        });
        
        // Đợi để Cloudflare challenge hoàn thành (nếu có)
        try {
            console.log('[PROXY] Step 2: Waiting for Cloudflare challenge...');
            await page.waitForFunction(
                () => {
                    const challenge = document.querySelector('#challenge-form, .cf-browser-verification, #cf-challenge-running, .cf-im-under-attack');
                    return !challenge || challenge.style.display === 'none' || challenge.offsetParent === null;
                },
                { timeout: 30000 }
            );
            console.log('[PROXY] Cloudflare challenge completed (or no challenge)');
        } catch (e) {
            console.log('[PROXY] No Cloudflare challenge detected or timeout');
        }
        
        // Đợi thêm để đảm bảo cookies được set
        await page.waitForTimeout(3000);
        
        // Navigate đến API endpoint để trigger thêm cookies nếu cần
        const testUrl = TARGET_URL + '/v1/models';
        console.log(`[PROXY] Step 3: Navigating to API endpoint: ${testUrl}`);
        await page.goto(testUrl, {
            waitUntil: 'networkidle2',
            timeout: 60000,
        });
        
        await page.waitForTimeout(2000);

        // Lấy cookies từ domain (cả root và subdomain)
        const cookies = await page.cookies();
        cfCookies = cookies;
        lastCookieUpdate = Date.now();
        
        console.log(`[PROXY] Cookies refreshed: ${cookies.length} cookies`);
        let hasCFCookies = false;
        cookies.forEach(cookie => {
            if (cookie.name.includes('cf_') || cookie.name.includes('__cf')) {
                console.log(`[PROXY] CF Cookie: ${cookie.name} = ${cookie.value.substring(0, 30)}... (domain: ${cookie.domain})`);
                hasCFCookies = true;
            }
        });
        
        // Nếu không có CF cookies, log tất cả cookies để debug
        if (!hasCFCookies) {
            console.log('[PROXY] No Cloudflare cookies found. All cookies:');
            cookies.forEach(cookie => {
                console.log(`[PROXY]   - ${cookie.name} (domain: ${cookie.domain}, path: ${cookie.path})`);
            });
            console.log('[PROXY] Note: Cloudflare may not require cookies, or cookies are set via JavaScript');
        }
    } catch (error) {
        console.error('[PROXY] Error refreshing cookies:', error.message);
        console.error('[PROXY] Stack:', error.stack);
    }
}

/**
 * Lấy cookies hiện tại (refresh nếu cần)
 */
async function getCookies() {
    const now = Date.now();
    if (!cfCookies || (now - lastCookieUpdate) > COOKIE_REFRESH_INTERVAL) {
        await refreshCookies();
    }
    return cfCookies || [];
}

/**
 * Forward request đến target bằng Puppeteer (thực sự dùng browser)
 */
async function forwardRequest(req, res) {
    try {
        // Parse request URL
        const requestPath = req.url;
        const targetUrl = new URL(requestPath, TARGET_URL);
        const method = req.method;
        
        console.log(`[PROXY] Forwarding ${method} ${requestPath} → ${targetUrl.href}`);
        console.log(`[PROXY] Request headers:`, Object.keys(req.headers));
        
        // Collect request body
        let body = [];
        let bodyReceived = false;
        
        req.on('data', chunk => {
            console.log(`[PROXY] Received data chunk, size: ${chunk.length}`);
            body.push(chunk);
        });
        
        req.on('end', async () => {
            console.log(`[PROXY] Request end event fired, total chunks: ${body.length}`);
            bodyReceived = true;
            try {
                const requestBody = Buffer.concat(body);
                console.log('[PROXY] Request body received, buffer length:', requestBody.length);
                const bodyText = requestBody.length > 0 ? requestBody.toString('utf8') : null;
                console.log('[PROXY] Request body text length:', bodyText ? bodyText.length : 0);
                if (bodyText) {
                    console.log('[PROXY] Request body preview (first 200 chars):', bodyText.substring(0, 200));
                }
                
                // Đảm bảo page đã sẵn sàng
                if (!page) {
                    throw new Error('Puppeteer page not initialized');
                }
                
                // Lấy cookies hiện tại để log
                const cookies = await page.cookies();
                console.log(`[PROXY] Current cookies: ${cookies.length} cookies`);
                
                // Dùng Puppeteer để thực hiện request trong browser context với timeout
                console.log('[PROXY] Executing fetch in browser context...');
                const response = await Promise.race([
                    page.evaluate(async ({ url, method, headers, body }) => {
                    try {
                        const fetchOptions = {
                            method: method,
                            headers: {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                                ...headers,
                            },
                        };
                        
                        if (body) {
                            fetchOptions.body = body;
                        }
                        
                        console.log('[BROWSER] Fetching:', url, 'Method:', method);
                        const response = await fetch(url, fetchOptions);
                        const responseText = await response.text();
                        
                        console.log('[BROWSER] Response status:', response.status, response.statusText);
                        console.log('[BROWSER] Response length:', responseText.length);
                        
                        return {
                            status: response.status,
                            statusText: response.statusText,
                            headers: Object.fromEntries(response.headers.entries()),
                            body: responseText,
                        };
                    } catch (error) {
                        console.error('[BROWSER] Fetch error:', error.message);
                        return {
                            error: error.message,
                            stack: error.stack,
                        };
                    }
                }, {
                    url: targetUrl.href,
                    method: method,
                    headers: {
                        'Authorization': req.headers['authorization'] || req.headers['Authorization'] || '',
                    },
                    body: bodyText,
                    }),
                    new Promise((_, reject) => 
                        setTimeout(() => reject(new Error('Puppeteer evaluate timeout after 30s')), 30000)
                    ),
                ]);
                
                console.log('[PROXY] Puppeteer evaluate completed');
                
                // Kiểm tra nếu có error từ browser
                if (response && response.error) {
                    console.error('[PROXY] Browser error:', response.error);
                    console.error('[PROXY] Browser stack:', response.stack);
                    res.writeHead(500);
                    res.end(JSON.stringify({ error: response.error }));
                    return;
                }
                
                // Kiểm tra response
                if (!response) {
                    throw new Error('No response from Puppeteer');
                }
                
                // Log response
                console.log(`[PROXY] Response: ${response.status} ${response.statusText}`);
                if (response.body) {
                    const preview = response.body.substring(0, Math.min(500, response.body.length));
                    console.log(`[PROXY] Response preview (first 500 chars): ${preview}`);
                    
                    // Kiểm tra nếu response là HTML (Cloudflare challenge)
                    if (response.body.includes('<html') || response.body.includes('cloudflare')) {
                        console.error('[PROXY] ⚠️ Response appears to be HTML (Cloudflare challenge?)');
                        console.error('[PROXY] Full response (first 1000 chars):', response.body.substring(0, 1000));
                    }
                } else {
                    console.error('[PROXY] ⚠️ Response body is empty or undefined');
                }
                
                // Set response headers
                const responseHeaders = response.headers || {};
                delete responseHeaders['content-encoding'];
                delete responseHeaders['transfer-encoding'];
                
                res.writeHead(response.status || 500, responseHeaders);
                res.end(response.body || JSON.stringify({ error: 'Empty response from proxy' }));
                
            } catch (error) {
                console.error('[PROXY] Error in Puppeteer request:', error.message);
                console.error('[PROXY] Stack:', error.stack);
                if (!res.headersSent) {
                    res.writeHead(500);
                    res.end(JSON.stringify({ error: error.message, details: error.stack }));
                }
            }
        });
        
        // Timeout fallback nếu request end không được trigger
        setTimeout(() => {
            if (!bodyReceived) {
                console.error('[PROXY] ⚠️ Request end event not fired after 5s, forcing forward');
                req.on('end', () => {}); // Dummy handler để tránh error
                // Force process request
                const requestBody = Buffer.concat(body);
                const bodyText = requestBody.length > 0 ? requestBody.toString('utf8') : null;
                forwardRequestWithBody(req, res, targetUrl, method, bodyText).catch(err => {
                    console.error('[PROXY] Error in forced forward:', err);
                    if (!res.headersSent) {
                        res.writeHead(500);
                        res.end(JSON.stringify({ error: err.message }));
                    }
                });
            }
        }, 5000);
        
    } catch (error) {
        console.error('[PROXY] Error:', error.message);
        console.error('[PROXY] Stack:', error.stack);
        if (!res.headersSent) {
            res.writeHead(500);
            res.end(JSON.stringify({ error: error.message }));
        }
    }
}

/**
 * Helper function để forward request với body
 */
async function forwardRequestWithBody(req, res, targetUrl, method, bodyText) {
    console.log('[PROXY] forwardRequestWithBody called');
    console.log('[PROXY] Request body text length:', bodyText ? bodyText.length : 0);
    if (bodyText) {
        console.log('[PROXY] Request body preview (first 200 chars):', bodyText.substring(0, 200));
    }
    
    // Đảm bảo page đã sẵn sàng
    if (!page) {
        throw new Error('Puppeteer page not initialized');
    }
    
    // Lấy cookies hiện tại để log
    const cookies = await page.cookies();
    console.log(`[PROXY] Current cookies: ${cookies.length} cookies`);
    
    // Dùng Puppeteer để thực hiện request trong browser context với timeout
    console.log('[PROXY] Executing fetch in browser context...');
    const response = await Promise.race([
        page.evaluate(async ({ url, method, headers, body }) => {
            try {
                const fetchOptions = {
                    method: method,
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        ...headers,
                    },
                };
                
                if (body) {
                    fetchOptions.body = body;
                }
                
                console.log('[BROWSER] Fetching:', url, 'Method:', method);
                const response = await fetch(url, fetchOptions);
                const responseText = await response.text();
                
                console.log('[BROWSER] Response status:', response.status, response.statusText);
                console.log('[BROWSER] Response length:', responseText.length);
                
                return {
                    status: response.status,
                    statusText: response.statusText,
                    headers: Object.fromEntries(response.headers.entries()),
                    body: responseText,
                };
            } catch (error) {
                console.error('[BROWSER] Fetch error:', error.message);
                return {
                    error: error.message,
                    stack: error.stack,
                };
            }
        }, {
            url: targetUrl.href,
            method: method,
            headers: {
                'Authorization': req.headers['authorization'] || req.headers['Authorization'] || '',
            },
            body: bodyText,
        }),
        new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Puppeteer evaluate timeout after 30s')), 30000)
        ),
    ]);
    
    console.log('[PROXY] Puppeteer evaluate completed');
    
    // Kiểm tra nếu có error từ browser
    if (response && response.error) {
        console.error('[PROXY] Browser error:', response.error);
        console.error('[PROXY] Browser stack:', response.stack);
        if (!res.headersSent) {
            res.writeHead(500);
            res.end(JSON.stringify({ error: response.error }));
        }
        return;
    }
    
    // Kiểm tra response
    if (!response) {
        throw new Error('No response from Puppeteer');
    }
    
    // Log response
    console.log(`[PROXY] Response: ${response.status} ${response.statusText}`);
    if (response.body) {
        const preview = response.body.substring(0, Math.min(500, response.body.length));
        console.log(`[PROXY] Response preview (first 500 chars): ${preview}`);
        
        // Kiểm tra nếu response là HTML (Cloudflare challenge)
        if (response.body.includes('<html') || response.body.includes('cloudflare')) {
            console.error('[PROXY] ⚠️ Response appears to be HTML (Cloudflare challenge?)');
            console.error('[PROXY] Full response (first 1000 chars):', response.body.substring(0, 1000));
        }
    } else {
        console.error('[PROXY] ⚠️ Response body is empty or undefined');
    }
    
    // Set response headers
    const responseHeaders = response.headers || {};
    delete responseHeaders['content-encoding'];
    delete responseHeaders['transfer-encoding'];
    
    if (!res.headersSent) {
        res.writeHead(response.status || 500, responseHeaders);
        res.end(response.body || JSON.stringify({ error: 'Empty response from proxy' }));
    }
}

/**
 * Main server
 */
async function startServer() {
    await initBrowser();
    
    const server = http.createServer(async (req, res) => {
        // CORS headers
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        
        if (req.method === 'OPTIONS') {
            res.writeHead(200);
            res.end();
            return;
        }
        
        await forwardRequest(req, res);
    });
    
    server.listen(PROXY_PORT, () => {
        console.log(`[PROXY] Cloudflare Bypass Proxy listening on port ${PROXY_PORT}`);
        console.log(`[PROXY] Target: ${TARGET_URL}`);
    });
    
    // Graceful shutdown
    process.on('SIGTERM', async () => {
        console.log('[PROXY] Shutting down...');
        if (browser) {
            await browser.close();
        }
        server.close();
        process.exit(0);
    });
}

// Start server
startServer().catch(console.error);

