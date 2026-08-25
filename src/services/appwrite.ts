/**
 * @deprecated Appwrite backend has been replaced by Convex.
 * See src/services/convex.ts for current backend operations.
 */
export const AppwriteService = {
  async getCurrentUser() {
    return null;
  },

  async syncOpportunityToCloud() {
    // Deprecated: Migrated to ConvexService
  },

  async fetchOpportunitiesFromCloud() {
    return [];
  }
};

export default AppwriteService;
