import { Worker } from "bullmq";

const connection = { url: process.env.REDIS_URL ?? "redis://redis:6379" };

new Worker("jobs", async (job) => {
  console.log(`processed job ${job.id}`, job.data);
  return { status: "ok" };
}, { connection });

console.log("BullMQ worker running");
