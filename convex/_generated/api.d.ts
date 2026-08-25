import type { ApiFromModules } from "convex/server";
import type * as opportunities from "../opportunities.js";

export declare const api: ApiFromModules<{
  opportunities: typeof opportunities;
}>;
