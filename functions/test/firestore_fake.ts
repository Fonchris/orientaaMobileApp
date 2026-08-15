/**
 * Minimal in-memory Firestore fake for unit tests.
 *
 * Supports the document-level operations the tested code paths use:
 * collection().doc().get()/update()/set(), and db.runTransaction with
 * tx.get()/update()/set(). FieldValue sentinels are handled by the
 * firebase-admin mock (serverTimestamp -> {toMillis}, delete -> 'DEL').
 *
 * Queries (where/orderBy/limit) are intentionally not implemented — the
 * money-path functions under test use doc reads + transactions only.
 */

export interface DocSnap {
  exists: boolean;
  data: () => any;
  ref: FakeDocRef;
}

let autoId = 0;

/**
 * Minimal equality-query over the fake store: `where(field, '==', value)`
 * scans documents under a collection prefix and keeps exact matches.
 */
export class FakeQuery {
  constructor(
    private store: Map<string, any>,
    private prefix: string,
    private filters: Array<{ field: string; value: any }>,
  ) {}

  async get(): Promise<{
    docs: Array<{ id: string; data: () => any; ref: FakeDocRef }>;
  }> {
    const docs: Array<{ id: string; data: () => any; ref: FakeDocRef }> = [];
    for (const [path, data] of this.store) {
      if (!path.startsWith(this.prefix + '/')) continue;
      if (!data || typeof data !== 'object') continue;
      if (!this.filters.every((f) => data[f.field] === f.value)) continue;
      const id = path.slice(this.prefix.length + 1);
      docs.push({ id, data: () => data, ref: new FakeDocRef(this.store, path) });
    }
    return { docs };
  }
}

function makeCollection(store: Map<string, any>, name: string) {
  return {
    doc: (id: string) => new FakeDocRef(store, `${name}/${id}`),
    where: (field: string, _op: string, value: any) =>
      new FakeQuery(store, name, [{ field, value }]),
    add: async (data: Record<string, any>) => {
      const id = `auto-${(autoId += 1)}`;
      store.set(`${name}/${id}`, data);
      return { id };
    },
  };
}

export class FakeDocRef {
  constructor(
    private store: Map<string, any>,
    readonly path: string,
  ) {}

  get(): Promise<DocSnap> {
    const data = this.store.get(this.path);
    return Promise.resolve({
      exists: data !== undefined,
      data: () => data,
      ref: this,
    });
  }

  update(patch: Record<string, any>): Promise<void> {
    const current = this.store.get(this.path) ?? {};
    const merged: Record<string, any> = { ...current };
    for (const [k, v] of Object.entries(patch)) {
      if (v === 'DEL') {
        delete merged[k];
      } else {
        merged[k] = v;
      }
    }
    this.store.set(this.path, merged);
    return Promise.resolve();
  }

  set(data: Record<string, any>, opts?: { merge?: boolean }): Promise<void> {
    if (opts?.merge) {
      this.store.set(this.path, {
        ...(this.store.get(this.path) ?? {}),
        ...data,
      });
    } else {
      this.store.set(this.path, data);
    }
    return Promise.resolve();
  }

  collection(name: string) {
    return makeCollection(this.store, `${this.path}/${name}`);
  }
}

export class FakeFirestore {
  readonly store = new Map<string, any>();

  constructor(initial?: Record<string, any>) {
    if (initial) {
      for (const [k, v] of Object.entries(initial)) this.store.set(k, v);
    }
  }

  collection(name: string) {
    return makeCollection(this.store, name);
  }

  runTransaction<T>(cb: (tx: any) => Promise<T>): Promise<T> {
    return cb({
      get: (ref: FakeDocRef) => ref.get(),
      update: (ref: FakeDocRef, data: Record<string, any>) => ref.update(data),
      set: (ref: FakeDocRef, data: Record<string, any>, opts?: any) => ref.set(data, opts),
    });
  }
}
