import prismaPkg from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { config } from 'dotenv';

config();

const { PrismaClient } = prismaPkg;

// Fallback to the Prisma Cloud connection string when DATABASE_URL is not provided
const DEFAULT_DATABASE_URL = 'postgres://092217ef3a85104fb1d3a6b0b33e523beb082967052d03b73ce4647103313c7d:sk_HJG9ncTQjOlIoZjnAsI0f@db.prisma.io:5432/postgres?sslmode=require';

const connectionString = process.env.DATABASE_URL || DEFAULT_DATABASE_URL;

const pool = new pg.Pool({ 
    connectionString,
    ssl: { rejectUnauthorized: false }
});
const adapter = new PrismaPg(pool);

const prisma = new PrismaClient({
    adapter,
    log: ['error', 'warn']
});

export { prisma };