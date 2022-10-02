import { setTimeout } from "node:timers/promises"
await setTimeout(1000)

//
export const sleep = (ms: number) => new Promise(res => setTimeout(res, ms))
