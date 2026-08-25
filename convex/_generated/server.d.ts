import {
  GenericQueryCtx,
  GenericMutationCtx,
  GenericActionCtx,
} from "convex/server";
import { DataModel } from "./dataModel";

export type QueryCtx = GenericQueryCtx<DataModel>;
export type MutationCtx = GenericMutationCtx<DataModel>;
export type ActionCtx = GenericActionCtx<DataModel>;

export declare const query: <Args extends Record<string, any>, Output>(
  func: {
    args?: Args;
    handler: (ctx: QueryCtx, args: any) => Promise<Output> | Output;
  }
) => any;

export declare const mutation: <Args extends Record<string, any>, Output>(
  func: {
    args?: Args;
    handler: (ctx: MutationCtx, args: any) => Promise<Output> | Output;
  }
) => any;

export declare const action: <Args extends Record<string, any>, Output>(
  func: {
    args?: Args;
    handler: (ctx: ActionCtx, args: any) => Promise<Output> | Output;
  }
) => any;
