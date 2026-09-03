/** 仅覆盖 Google 迁移所需的 protobuf varint 与 length-delimited 字段。 */
export class ProtoWriter {
  private bytes: number[] = [];

  writeVarintField(field: number, value: number): void {
    this.writeVarint((field << 3) | 0);
    this.writeVarint(value);
  }

  writeBytesField(field: number, data: Uint8Array): void {
    this.writeVarint((field << 3) | 2);
    this.writeVarint(data.length);
    for (let i: number = 0; i < data.length; i++) {
      this.bytes.push(data[i]);
    }
  }

  toBytes(): Uint8Array {
    return new Uint8Array(this.bytes);
  }

  writeVarint(value: number): void {
    let remaining: number = value;
    if (remaining < 0 || !Number.isFinite(remaining)) {
      remaining = 0;
    }
    remaining = Math.floor(remaining);
    while (remaining >= 0x80) {
      this.bytes.push((remaining & 0x7F) | 0x80);
      remaining = Math.floor(remaining / 128);
    }
    this.bytes.push(remaining);
  }
}

export class ProtoReader {
  private offset: number = 0;
  private bytes: Uint8Array;

  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
  }

  hasRemaining(): boolean {
    return this.offset < this.bytes.length;
  }

  readTag(): number {
    return this.readVarint();
  }

  readVarint(): number {
    let value: number = 0;
    let multiplier: number = 1;
    for (let i: number = 0; i < 10 && this.offset < this.bytes.length; i++) {
      const byte: number = this.bytes[this.offset];
      this.offset++;
      value += (byte & 0x7F) * multiplier;
      if ((byte & 0x80) === 0) {
        return value;
      }
      multiplier *= 128;
    }
    return value;
  }

  readBytes(): Uint8Array {
    const length: number = this.readVarint();
    if (length < 0 || this.offset + length > this.bytes.length) {
      this.offset = this.bytes.length;
      return new Uint8Array(0);
    }
    const value: Uint8Array = this.bytes.slice(this.offset, this.offset + length);
    this.offset += length;
    return value;
  }

  skip(wireType: number): void {
    if (wireType === 0) {
      this.readVarint();
    } else if (wireType === 1) {
      this.offset = Math.min(this.offset + 8, this.bytes.length);
    } else if (wireType === 2) {
      this.readBytes();
    } else if (wireType === 5) {
      this.offset = Math.min(this.offset + 4, this.bytes.length);
    } else {
      this.offset = this.bytes.length;
    }
  }
}
