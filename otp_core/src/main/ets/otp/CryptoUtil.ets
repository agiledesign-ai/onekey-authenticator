/**
 * 加密原语：Base32 解码 + HMAC-SHA1（纯 TypeScript 同步实现）。
 * 不依赖 cryptoFramework 的异步 API，可在 build 路径同步调用。
 */

const BASE32_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/** Base32 解码为字节数组（RFC 4648，忽略空格/填充符）。 */
export function base32Decode(input: string): Uint8Array {
  const clean: string = input.toUpperCase().replace(/[^A-Z2-7]/g, '');
  const bytes: number[] = [];
  let buffer: number = 0;
  let bitsLeft: number = 0;

  for (let i: number = 0; i < clean.length; i++) {
    const ch: string = clean.charAt(i);
    const value: number = BASE32_ALPHABET.indexOf(ch);
    if (value < 0) {
      continue;
    }
    buffer = ((buffer << 5) | value) >>> 0;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bytes.push((buffer >> (bitsLeft - 8)) & 0xFF);
      bitsLeft -= 8;
    }
  }
  return new Uint8Array(bytes);
}

// ── SHA-1 实现 ──────────────────────────────────────────────

const SHA1_K: number[] = [0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6];
const SHA1_H0: number[] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];

/** 对 data 计算 SHA-1 摘要，返回 20 字节。 */
function sha1(data: Uint8Array): Uint8Array {
  const padded: Uint8Array = sha1Pad(data);
  let h0: number = SHA1_H0[0];
  let h1: number = SHA1_H0[1];
  let h2: number = SHA1_H0[2];
  let h3: number = SHA1_H0[3];
  let h4: number = SHA1_H0[4];

  for (let off: number = 0; off < padded.length; off += 64) {
    const w: number[] = new Array(80);
    for (let i: number = 0; i < 16; i++) {
      w[i] = ((padded[off + i * 4] << 24)
        | (padded[off + i * 4 + 1] << 16)
        | (padded[off + i * 4 + 2] << 8)
        | padded[off + i * 4 + 3]) >>> 0;
    }
    for (let i: number = 16; i < 80; i++) {
      const t: number = (w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16]) >>> 0;
      w[i] = ((t << 1) | (t >>> 31)) >>> 0;
    }

    let a: number = h0;
    let b: number = h1;
    let c: number = h2;
    let d: number = h3;
    let e: number = h4;

    for (let i: number = 0; i < 80; i++) {
      let f: number;
      let k: number;
      if (i < 20) {
        f = ((b & c) | ((~b) & d)) >>> 0;
        k = SHA1_K[0];
      } else if (i < 40) {
        f = (b ^ c ^ d) >>> 0;
        k = SHA1_K[1];
      } else if (i < 60) {
        f = ((b & c) | (b & d) | (c & d)) >>> 0;
        k = SHA1_K[2];
      } else {
        f = (b ^ c ^ d) >>> 0;
        k = SHA1_K[3];
      }
      const temp: number = ((((a << 5) | (a >>> 27)) >>> 0) + f + e + k + w[i]) >>> 0;
      e = d;
      d = c;
      c = ((b << 30) | (b >>> 2)) >>> 0;
      b = a;
      a = temp;
    }
    h0 = (h0 + a) >>> 0;
    h1 = (h1 + b) >>> 0;
    h2 = (h2 + c) >>> 0;
    h3 = (h3 + d) >>> 0;
    h4 = (h4 + e) >>> 0;
  }

  const result: Uint8Array = new Uint8Array(20);
  const h: number[] = [h0, h1, h2, h3, h4];
  for (let i: number = 0; i < 5; i++) {
    result[i * 4] = (h[i] >>> 24) & 0xFF;
    result[i * 4 + 1] = (h[i] >>> 16) & 0xFF;
    result[i * 4 + 2] = (h[i] >>> 8) & 0xFF;
    result[i * 4 + 3] = h[i] & 0xFF;
  }
  return result;
}

/** SHA-1 填充：追加 0x80 + 零填充 + 64 位大端长度。 */
function sha1Pad(msg: Uint8Array): Uint8Array {
  const origLen: number = msg.length;
  const bitLen: number = origLen * 8;
  let paddedLen: number = origLen + 1;
  while (paddedLen % 64 !== 56) {
    paddedLen++;
  }
  paddedLen += 8;

  const result: Uint8Array = new Uint8Array(paddedLen);
  result.set(msg, 0);
  result[origLen] = 0x80;
  result[paddedLen - 4] = (bitLen >>> 24) & 0xFF;
  result[paddedLen - 3] = (bitLen >>> 16) & 0xFF;
  result[paddedLen - 2] = (bitLen >>> 8) & 0xFF;
  result[paddedLen - 1] = bitLen & 0xFF;
  return result;
}

// ── HMAC-SHA1 ───────────────────────────────────────────────

/** HMAC-SHA1(key, message)，返回 20 字节摘要。 */
export function hmacSha1(key: Uint8Array, message: Uint8Array): Uint8Array {
  let processedKey: Uint8Array = key;
  if (key.length > 64) {
    processedKey = sha1(key);
  }

  const paddedKey: Uint8Array = new Uint8Array(64);
  paddedKey.set(processedKey, 0);

  const innerPad: Uint8Array = new Uint8Array(64);
  const outerPad: Uint8Array = new Uint8Array(64);
  for (let i: number = 0; i < 64; i++) {
    innerPad[i] = paddedKey[i] ^ 0x36;
    outerPad[i] = paddedKey[i] ^ 0x5C;
  }

  // inner = SHA1(ipad ‖ message)
  const innerMsg: Uint8Array = new Uint8Array(64 + message.length);
  innerMsg.set(innerPad, 0);
  innerMsg.set(message, 64);
  const innerHash: Uint8Array = sha1(innerMsg);

  // outer = SHA1(opad ‖ inner)
  const outerMsg: Uint8Array = new Uint8Array(64 + 20);
  outerMsg.set(outerPad, 0);
  outerMsg.set(innerHash, 64);
  return sha1(outerMsg);
}
