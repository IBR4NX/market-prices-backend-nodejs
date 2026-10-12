import { Router, Request, Response } from "express";
import pool from "../../database";
import { BASE_URL } from "../../config";
import { escapeXml } from "./sitemap";
const router = Router();
type SitemapUrl = {
  url: string;
  lastmod?: string | Date | null;
  priority: string;
};

router.get("/:type", async (_req: Request, res: Response) => {
  try {
    const sender = _req.query.sender as string;
    console.log("Generating RSS feed for type:", _req.params.type, "with sender:", _req.query.sender);
    const MAP_URL = `https://${sender || BASE_URL}`;
    const HUB_URL = "https://pubsubhubbub.appspot.com/";
    const FEED_URL = `${MAP_URL}/sitemap/custom/${_req.params.type}.xml`;
    
    const result = await pool.query(`select name, description, slug FROM products;`,);
    const sortedRows = result.rows.sort(
      (a, b) =>
        new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
    );
    const items = sortedRows.map((price) => {
      // const citySlug = price.city_name.trim().replace(/\s+/g, "-");

      const productSlug = price.slug.trim().replace(/\s+/g, "-");

      const url = `/${productSlug}`;

      return {
        title: `سعر ${price.product_name} في ${price.city_name}`,
        url: `${MAP_URL}${url}`,
        description: `سعر ${price.product_name}  في محافظة ${price.city_name} اليوم هو ${price.price} ريال يمني لكل ${price.quantity} ${price.unit}. المنتج ضمن فئة ${price.category_name}،  مع أحدث تحديث متوفر للسعر, وأسباب التغيير`,
        lastmod: price.updated_at,
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