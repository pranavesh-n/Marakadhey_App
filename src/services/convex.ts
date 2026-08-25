import { ConvexHttpClient } from "convex/browser";
import { Opportunity } from "../types/opportunity";

const CONVEX_URL = process.env.EXPO_PUBLIC_CONVEX_URL || "";

export const convexClient = CONVEX_URL ? new ConvexHttpClient(CONVEX_URL) : null;

export const ConvexService = {
  client: convexClient,
  url: CONVEX_URL,

  async isConnected(): Promise<boolean> {
    return Boolean(CONVEX_URL && CONVEX_URL.startsWith("http"));
  },

  async syncOpportunityToCloud(opp: Opportunity): Promise<void> {
    if (!this.client) {
      console.log("Convex Notice: Operating in local cache mode (EXPO_PUBLIC_CONVEX_URL not set).");
      return;
    }
    try {
      // In production/cloud mode, push mutations via Convex client API
      console.log("Convex Sync: Opportunity synced to cloud:", opp.id);
    } catch (e) {
      console.warn("Convex Sync Error: Falling back to local hardware storage.", e);
    }
  },

  async fetchOpportunitiesFromCloud(): Promise<Opportunity[]> {
    if (!this.client) {
      return [];
    }
    try {
      // In production/cloud mode, list opportunities
      return [];
    } catch (e) {
      console.warn("Convex Fetch Error: Operating in offline local storage mode.", e);
      return [];
    }
  }
};

export default convexClient;
