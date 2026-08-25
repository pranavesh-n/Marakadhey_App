import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// 1. Fetch all opportunities for a user or general list
export const list = query({
  args: {
    userId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    if (args.userId) {
      return await ctx.db
        .query("opportunities")
        .filter((q) => q.eq(q.field("userId"), args.userId))
        .order("desc")
        .collect();
    }
    return await ctx.db.query("opportunities").order("desc").collect();
  },
});

// 2. Add an opportunity with Rule 3 server-side throttling check (Max 200 uncompleted deadlines)
export const create = mutation({
  args: {
    userId: v.optional(v.string()),
    title: v.string(),
    description: v.optional(v.string()),
    websiteUrl: v.optional(v.string()),
    category: v.string(),
    priority: v.string(),
    status: v.string(),
    deadline: v.string(),
    reminderTimes: v.optional(v.array(v.string())),
    isRecurring: v.optional(v.boolean()),
    recurrenceRule: v.optional(v.union(v.string(), v.null())),
    checklist: v.array(
      v.object({
        id: v.string(),
        task: v.string(),
        completed: v.boolean(),
      })
    ),
    tags: v.array(v.string()),
    notes: v.optional(v.string()),
    pinned: v.boolean(),
    calendarSynced: v.boolean(),
    history: v.array(
      v.object({
        id: v.string(),
        action: v.string(),
        timestamp: v.string(),
        note: v.optional(v.string()),
      })
    ),
    createdAt: v.string(),
    updatedAt: v.string(),
  },
  handler: async (ctx, args) => {
    // Check throttle limit: Block if uncompleted count >= 200
    const uncompleted = await ctx.db
      .query("opportunities")
      .filter((q) =>
        q.and(
          q.neq(q.field("status"), "COMPLETED"),
          q.neq(q.field("status"), "ARCHIVED")
        )
      )
      .collect();

    if (uncompleted.length >= 200) {
      throw new Error(
        "THROTTLE_LIMIT_REACHED: Maximum 200 uncompleted deadlines allowed to maintain 100% free tier operations."
      );
    }

    return await ctx.db.insert("opportunities", args);
  },
});

// 3. Update opportunity fields
export const update = mutation({
  args: {
    id: v.id("opportunities"),
    updates: v.object({
      title: v.optional(v.string()),
      description: v.optional(v.string()),
      websiteUrl: v.optional(v.string()),
      category: v.optional(v.string()),
      priority: v.optional(v.string()),
      status: v.optional(v.string()),
      deadline: v.optional(v.string()),
      checklist: v.optional(
        v.array(
          v.object({
            id: v.string(),
            task: v.string(),
            completed: v.boolean(),
          })
        )
      ),
      tags: v.optional(v.array(v.string())),
      notes: v.optional(v.string()),
      pinned: v.optional(v.boolean()),
      calendarSynced: v.optional(v.boolean()),
      history: v.optional(
        v.array(
          v.object({
            id: v.string(),
            action: v.string(),
            timestamp: v.string(),
            note: v.optional(v.string()),
          })
        )
      ),
      updatedAt: v.string(),
    }),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.id, args.updates);
  },
});

// 4. Delete opportunity
export const remove = mutation({
  args: {
    id: v.id("opportunities"),
  },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.id);
  },
});
