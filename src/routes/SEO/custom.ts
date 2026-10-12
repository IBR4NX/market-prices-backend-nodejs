import { Router, Request, Response } from "express";
import pool from "../../database";
import { BASE_URL } from "../../config";
import { escapeXml } from "./sitemap";
const router = Router();
interface ProductPrice {
  price: number | string;
  city: {
    name: string;
  } | null;
}

interface Product {
  id: string | number;
  name: string;
  slug: string;
  description?: string | null;
  quantity?: number | string | null;
  unit?: string | null;
  updated_at: string;
  category?: {
    name: string;
  } | null;
  current_prices?: ProductPrice[];
}
// sitemap/custom/products.xml?sender=ibovs.vercel.app
router.get("/:type", async (_req: Request, res: Response) => {
  try {
    const sender = _req.query.sender as string;
    const type = _req.params.type

    const MAP_URL = `https://${sender || BASE_URL}`;
    const HUB_URL = "https://pubsubhubbub.appspot.com/";
    const FEED_URL = `${MAP_URL}/sitemap/custom/${type}?sender=${sender}`;
    const result = await pool.query(`SELECT * FROM get_products(NULL);`);

    const sortedRows: Product[] = result.rows
      .map(
        (row: { product?: Product } & Partial<Product>) =>
          row.product ?? (row as Product),
      )
      .sort(
        (a: Product, b: Product) =>
          new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
      );

    const items = sortedRows.map((product: Product) => {
      const productName = product.name.trim();
      const productSlug = product.slug;

      const productQuantity =
        product.quantity != null && product.unit
          ? `${product.quantity} ${product.unit}`
          : "";

const prices = (product.current_prices ?? [])
  .filter((item) => item.city?.name && item.price != null)
  .sort((a, b) =>
    a.city!.name.localeCompare(b.city!.name, "ar"),
  );

const priceDetails = prices.map((item) => {
  const cityName = item.city!.name;
  const price = Number(item.price).toLocaleString("en-US");

  return `${cityName}: ${price} ريال`;
});

const description = [
  `كم سعر ${product.name} ${product.quantity ?? ""} ${product.unit ?? ""} في اليمن؟`,
  priceDetails.length
    ? `الأسعار حسب المدينة: ${priceDetails.join("، ")}.`
    : "لا تتوفر حاليًا أسعار مسجلة لهذا المنتج.",
  `تابع أسعار ${product.name} وقارن الأسعار بين المدن اليمنية عبر منصة أسعار اليمن.`,
]
  .filter(Boolean)
  .join(" ");



      const title = productQuantity
        ? `سعر ${productName} ${productQuantity} اليوم في اليمن`
        : `سعر ${productName} اليوم في اليمن حسب المدينة`;
      return {
        title,
        url: `${MAP_URL.replace(/\/+$/, "")}/${productSlug}`,
        description,
        lastmod: product.updated_at,
      };
    });

    const uniqueItems = Array.from(
      new Map(items.map((item) => [item.url, item])).values(),
    );

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" >
  <channel>
  <title>أسعار اليمن اليوم للمنتجات والسلع</title>
  <atom:link
  href="${escapeXml(HUB_URL)}"
  rel="hub"
/>
<atom:link
  href="${escapeXml(FEED_URL)}"
  rel="self"
  type="application/rss+xml"
/>
<description>تابع أحدث أسعار المنتجات والسلع في اليمن حسب المدينة، وتعرّف على أسعار المنتجات في صنعاء وتعز وعدن وغيرها من المدن اليمنية.</description>
    <link>${MAP_URL}/</link>
    <language>ar</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>

    ${uniqueItems
      .map(
        ({ title, url, description, lastmod }) => `
    <item>
      <title>${escapeXml(title)}</title>
      <link>${escapeXml(url)}</link>
      <guid isPermaLink="true">${escapeXml(url)}</guid>
      <description>${escapeXml(description)}</description>
      ${lastmod ? `<pubDate>${new Date(lastmod).toUTCString()}</pubDate>` : ""}
    </item>`,
      )
      .join("")}

  </channel>
</rss>`;

    res.status(200).type("application/rss+xml").send(xml);
  } catch (error) {
    console.error("RSS error:", error);
    res.status(500).send("Failed to generate RSS");
  }
});

export default router;
