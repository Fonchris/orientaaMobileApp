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

  collection(name: string): { doc: (id: string) => FakeDocRef } {
    return {
      doc: (id: string) => new FakeDocRef(this.store, `${this.path}/${name}/${id}`),
    };
  }
}

export class FakeFirestore {
  readonly store = new Map<string, any>();

  constructor(initial?: Record<string, any>) {
    if (initial) {
      for (const [k, v] of Object.entries(initial)) this.store.set(k, v);
    }
  }

  collection(name: string): { doc: (id: string) => FakeDocRef } {
    return {
      doc: (id: string) => new FakeDocRef(this.store, `${name}/${id}`),
    };
  }

  runTransaction<T>(cb: (tx: any) => Promise<T>): Promise<T> {
    return cb({
      get: (ref: FakeDocRef) => ref.get(),
      update: (ref: FakeDocRef, data: Record<string, any>) => ref.update(data),
      set: (ref: FakeDocRef, data: Record<string, any>, opts?: any) => ref.set(data, opts),
    });
  }
}
