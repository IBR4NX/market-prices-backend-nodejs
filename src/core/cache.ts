type CacheItem<T> = {
  data: T;
  expiry: number;
};

class MemoryCache {
  private store = new Map<string, CacheItem<any>>();
  private defaultTtl: number; // بالمللي ثانية

  constructor(defaultTtlMinutes: number = 5) {
    this.defaultTtl = defaultTtlMinutes * 60 * 1000;
  }

  /**
   * تعيين قيمة في الكاش
   * @param key مفتاح التخزين
   * @param data البيانات المراد تخزينها
   * @param ttlMinutes وقت انتهاء الصلاحية بالدقائق (اختياري)
   */
  set<T>(key: string, data: T, ttlMinutes?: number): void {
    const ttl = ttlMinutes ? ttlMinutes * 60 * 1000 : this.defaultTtl;
    const expiry = Date.now() + ttl;
    this.store.set(key, { data, expiry });
  }

  /**
   * جلب قيمة من الكاش (مع التحقق من انتهاء الصلاحية تلقائياً)
   */
  get<T>(key: string): T | null {
    const item = this.store.get(key);

    if (!item) return null;

    // إذا انتهت صلاحية الكاش، قم بحذفه وإرجاع null
    if (Date.now() > item.expiry) {
      this.store.delete(key);
      return null;
    }

    return item.data as T;
  }

  /**
   * حذف مفتاح محدد من الكاش
   */
  del(key: string): void {
    this.store.delete(key);
  }

  /**
   * مسح جميع المفاتيح التي تبدأ بنص معين (Useful for cache invalidation by prefix)
   * مثال: invalidatePattern("cities:list") سيحذف كل ما يتعلق بقائمة المدن
   */
  invalidatePattern(prefix: string): void {
    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
      }
    }
  }


  clear(): void {
    this.store.clear();
  }
}

export const cache = new MemoryCache(10);
