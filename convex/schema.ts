import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
    authProvider: v.string(),
    createdAt: v.string(),
  }).index("by_email", ["email"]),

  opportunities: defineTable({
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
  })
    .index("by_user", ["userId"])
    .index("by_status", ["status"])
    .index("by_deadline", ["deadline"]),
});
