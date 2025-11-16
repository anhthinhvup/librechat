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
        
        // Navigate đến target URL - dùng /v1 để trigger API endpoint
        const testUrl = TARGET_URL + '/v1/models';
        console.log(`[PROXY] Navigating to: ${testUrl}`);
        
        await page.goto(testUrl, {
            waitUntil: 'networkidle2',
            timeout: 60000,
        });

        // Đợi để Cloudflare challenge hoàn thành (nếu có)
        try {
            // Đợi tối đa 30s để challenge hoàn thành
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
        await page.waitForTimeout(5000);

        // Lấy cookies từ domain
        const cookies = await page.cookies();
        cfCookies = cookies;
        lastCookieUpdate = Date.now();
        
        console.log(`[PROXY] Cookies refreshed: ${cookies.length} cookies`);
        let hasCFCookies = false;
        cookies.forEach(cookie => {
            if (cookie.name.includes('cf_') || cookie.name.includes('__cf')) {
                console.log(`[PROXY] CF Cookie: ${cookie.name} = ${cookie.value.substring(0, 20)}...`);
                hasCFCookies = true;
            }
        });
        
        // Nếu không có CF cookies, log tất cả cookies để debug
        if (!hasCFCookies) {
            console.log('[PROXY] No Cloudflare cookies found. All cookies:');
            cookies.forEach(cookie => {
                console.log(`[PROXY]   - ${cookie.name} (domain: ${cookie.domain})`);
            });
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
 * Forward request đến target với cookies
 */
async function forwardRequest(req, res) {
    try {
        // Parse request URL - giữ nguyên path từ request
        const requestPath = req.url;
        const targetUrl = new URL(requestPath, TARGET_URL);
        const method = req.method;
        const headers = { ...req.headers };
        
        // Remove headers không cần thiết
        delete headers.host;
        delete headers['content-length'];
        
        // Lấy cookies từ Puppeteer
        const cookies = await getCookies();
        const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');
        if (cookieString) {
            headers['cookie'] = cookieString;
        }
        
        // Set headers giống browser
        headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
        headers['accept'] = headers['accept'] || 'application/json';
        headers['accept-encoding'] = 'gzip, deflate, br';
        headers['origin'] = TARGET_URL;
        headers['referer'] = TARGET_URL + '/';
        
        console.log(`[PROXY] Forwarding ${method} ${requestPath} → ${targetUrl.href}`);
        
        // Forward request
        const options = {
            hostname: targetUrl.hostname,
            port: targetUrl.port || 443,
            path: targetUrl.pathname + targetUrl.search,
            method: method,
            headers: headers,
        };
        
        const proxyReq = https.request(options, (proxyRes) => {
            // Copy response headers
            const responseHeaders = { ...proxyRes.headers };
            delete responseHeaders['content-encoding']; // Remove encoding để tránh double encoding
            res.writeHead(proxyRes.statusCode, responseHeaders);
            
            // Pipe response
            proxyRes.pipe(res);
        });
        
        proxyReq.on('error', (error) => {
            console.error('[PROXY] Error forwarding request:', error.message);
            res.writeHead(500);
            res.end(JSON.stringify({ error: error.message }));
        });
        
        // Pipe request body
        req.pipe(proxyReq);
        
    } catch (error) {
        console.error('[PROXY] Error:', error.message);
        res.writeHead(500);
        res.end(JSON.stringify({ error: error.message }));
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

