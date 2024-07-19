import { COOKIE_NAME } from './consts';
import { sealData, unsealData } from 'iron-session';
import { NextRequest, NextResponse } from 'next/server';

if (!process.env.SESSION_SECRET) {
    throw new Error('SESSION_SECRET cannot be empty.');
}

if (!process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID) {
    throw new Error('NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID cannot be empty.');
}

const SESSION_OPTIONS = {
    ttl: 60 * 60 * 24 * 30, // 30 days
    password: process.env.SESSION_SECRET,
};

export class Session {
    constructor(session) {
        this.nonce = session?.nonce;
        this.chainId = session?.chainId;
        this.address = session?.address;
    }

    static async fromRequest(req) {
        const sessionCookie = req.cookies.get(COOKIE_NAME)?.value;

        if (!sessionCookie) return new Session();
        return new Session(await unsealData(sessionCookie, SESSION_OPTIONS));
    }

    clear(res) {
        this.nonce = undefined;
        this.chainId = undefined;
        this.address = undefined;

        return this.persist(res);
    }

    toJSON() {
        return { nonce: this.nonce, address: this.address, chainId: this.chainId };
    }

    async persist(res) {
        res.cookies.set(COOKIE_NAME, await sealData(this.toJSON(), SESSION_OPTIONS), {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'development',
        });
    }
}

export default Session;
