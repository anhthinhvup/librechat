const axios = require('axios');
const logger = require('~/config/winston');

class Mem0Service {
  constructor() {
    this.apiUrl = process.env.MEM0_API_URL || 'http://mem0-server:8001';
    this.apiKey = process.env.MEM0_API_KEY;
    this.enabled = process.env.ENABLE_MEM0 === 'true' || process.env.ENABLE_MEM0 === true;
  }

  /**
   * Check if mem0 is enabled and available
   */
  async isAvailable() {
    if (!this.enabled) {
      return false;
    }
    try {
      const response = await axios.get(`${this.apiUrl}/health`, {
        timeout: 2000,
      });
      return response.status === 200;
    } catch (error) {
      logger.debug('[Mem0Service] Mem0 not available:', error.message);
      return false;
    }
  }

  /**
   * Add memories from conversation messages
   * @param {string} userId - User ID
   * @param {Array} messages - Array of messages with role and content
   * @returns {Promise<Object>} Result from mem0
   */
  async addMemories(userId, messages) {
    if (!this.enabled) {
      return null;
    }

    try {
      const available = await this.isAvailable();
      if (!available) {
        logger.debug('[Mem0Service] Mem0 not available, skipping');
        return null;
      }

      // Convert messages to mem0 format
      const mem0Messages = messages.map((msg) => ({
        role: msg.role || (msg.role === 'user' ? 'user' : 'assistant'),
        content: typeof msg.content === 'string' ? msg.content : JSON.stringify(msg.content),
      }));

      const response = await axios.post(
        `${this.apiUrl}/memories`,
        {
          user_id: userId,
          messages: mem0Messages,
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        }
      );

      if (response.data && response.data.success) {
        logger.info(`[Mem0Service] Added memories for user ${userId}`);
        return response.data;
      }

      return null;
    } catch (error) {
      logger.error('[Mem0Service] Error adding memories:', error.message);
      return null;
    }
  }

  /**
   * Get all memories for a user
   * @param {string} userId - User ID
   * @param {number} limit - Limit number of memories
   * @returns {Promise<Array>} Array of memories
   */
  async getMemories(userId, limit = 100) {
    if (!this.enabled) {
      return [];
    }

    try {
      const available = await this.isAvailable();
      if (!available) {
        return [];
      }

      const response = await axios.get(`${this.apiUrl}/memories/${userId}`, {
        params: { limit },
        timeout: 10000,
      });

      if (response.data && response.data.success) {
        return response.data.memories || [];
      }

      return [];
    } catch (error) {
      logger.error('[Mem0Service] Error getting memories:', error.message);
      return [];
    }
  }

  /**
   * Search memories for a user
   * @param {string} userId - User ID
   * @param {string} query - Search query
   * @param {number} limit - Limit number of results
   * @returns {Promise<Array>} Array of search results
   */
  async searchMemories(userId, query, limit = 10) {
    if (!this.enabled) {
      return [];
    }

    try {
      const available = await this.isAvailable();
      if (!available) {
        return [];
      }

      const response = await axios.post(
        `${this.apiUrl}/memories/search`,
        {
          user_id: userId,
          query,
          limit,
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }
      );

      if (response.data && response.data.success) {
        return response.data.results || [];
      }

      return [];
    } catch (error) {
      logger.error('[Mem0Service] Error searching memories:', error.message);
      return [];
    }
  }

  /**
   * Sync mem0 memories to MongoDB
   * This will convert mem0 memories to LibreChat memory format and store in MongoDB
   */
  async syncToMongoDB(userId, { setMemory, getAllUserMemories }) {
    if (!this.enabled) {
      return;
    }

    try {
      const mem0Memories = await this.getMemories(userId);
      if (!mem0Memories || mem0Memories.length === 0) {
        return;
      }

      const existingMemories = await getAllUserMemories(userId);
      const existingKeys = new Set(existingMemories.map((m) => m.key));

      // Import Tokenizer for token counting
      const { Tokenizer } = require('@librechat/api');

      for (const mem of mem0Memories) {
        try {
          // Extract key and value from mem0 memory format
          // mem0 returns memories in format: { memory: "...", metadata: {...} }
          const memoryText = mem.memory || mem.content || JSON.stringify(mem);
          const memoryKey = mem.metadata?.key || `mem0_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

          // Skip if already exists
          if (existingKeys.has(memoryKey)) {
            continue;
          }

          const tokenCount = Tokenizer.getTokenCount(memoryText, 'o200k_base');

          await setMemory({
            userId,
            key: memoryKey,
            value: memoryText,
            tokenCount,
          });

          logger.debug(`[Mem0Service] Synced memory ${memoryKey} to MongoDB`);
        } catch (error) {
          logger.error(`[Mem0Service] Error syncing memory to MongoDB:`, error);
        }
      }

      logger.info(`[Mem0Service] Synced ${mem0Memories.length} memories to MongoDB for user ${userId}`);
    } catch (error) {
      logger.error('[Mem0Service] Error syncing to MongoDB:', error);
    }
  }
}

module.exports = new Mem0Service();

