import { Router, Request, Response } from "express";
import pool from "../../database";
import { BASE_URL } from "../../config";

const router = Router();
type SitemapUrl = {
  url: string;
  lastmod?: string | Date | null;
  priority: string;
};
 import customRouter from "./custom";
router.use("/custom", customRouter);
router.get("/sitemap.xml", async (_req: Request, res: Response) => {
  try {
    const MAP_URL = `https://${(_req.query.sender as string) ?? BASE_URL}`;
    console.log(_req.query.sender);
    const [cities, products, categories] = await Promise.all([
      pool.query(`
        SELECT id,name, updated_at
        FROM cities
        WHERE is_active = true
      `),

      pool.query(`
        SELECT id,name, updated_at
        FROM products
        WHERE is_active = true
      `),

      pool.query(`
        SELECT id,name, updated_at
        FROM categories
        WHERE is_active = true
      `),
    ]);

    const urls: SitemapUrl[] = [
      {
        url: "/",
        priority: "1.0",
      },
      {
        url: "/prices",
        priority: "0.9",
      },
      {
        url: "/about",
        priority: "0.5",
      },

      ...cities.rows.map((city) => ({
        url: `/city/${city.name}`,
        lastmod: city.updated_at,
        priority: "0.8",
      })),

      ...products.rows.map((product) => ({
        url: `/product/${product.name}`,
        lastmod: product.updated_at,
        priority: "0.8",
      })),

      ...categories.rows.map((category) => ({
        url: `/category/${category.name}`,
        lastmod: category.updated_at,
        priority: "0.7",
      })),
    ];

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

${urls
  .map(
    ({ url, lastmod, priority }) => `
  <url>
    <loc>${MAP_URL}${url}</loc>
    ${lastmod ? `<lastmod>${new Date(lastmod).toISOString()}</lastmod>` : ""}
    <changefreq>daily</changefreq>
    <priority>${priority}</priority>
  </url>`,
  )
  .join("")}

</urlset>`;

    res.status(200).type("application/xml").send(xml);
  } catch (error) {
    console.error("Sitemap error:", error);

    res.status(500).send("Failed to generate sitemap");
  }
});

router.get("/sitemap2.xml", async (_req: Request, res: Response) => {
  try {
    const MAP_URL = `https://${(_req.query.sender as string) ?? BASE_URL}`;
    const result = await pool.query(
      `
      SELECT *
      FROM get_current_prices(
        $1::text,
        $2::text,
        $3::text
      )
      `,
      [null, null, null],
    );

    const urls = result.rows.map((price) => ({
      url: `/city/${price.city_name.trim().replace(/\s+/g, "-")}/product/${price.product_name.trim().replace(/\s+/g, "-")}`,
      lastmod: price.updated_at,
      priority: "0.8",
    }));

    const uniqueUrls = Array.from(
      new Map(urls.map((item) => [item.url, item])).values(),
    );

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset
  xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
>
${uniqueUrls
  .map(
    ({ url, lastmod, priority }) => `
  <url>
    <loc>${MAP_URL}${url}</loc>
    ${lastmod ? `<lastmod>${new Date(lastmod).toISOString()}</lastmod>` : ""}
    <changefreq>daily</changefreq>
    <priority>${priority}</priority>
  </url>`,
  )
  .join("")}
</urlset>`;

    res.status(200).type("application/xml").send(xml);
  } catch (error) {
    console.error("Sitemap error:", error);

    res.status(500).send("Failed to generate sitemap");
  }
});

router.get("/rss.xml", async (_req: Request, res: Response) => {
  try {
    const sender = _req.query.sender as string;
    const type = _req.params.type

    const MAP_URL = `https://${sender || BASE_URL}`;
    const HUB_URL = "https://pubsubhubbub.appspot.com/";
    const FEED_URL = `${MAP_URL}/sitemap/custom/${type}?sender=${sender}`;
    
    const result = await pool.query(
      `
      SELECT *
      FROM get_current_prices(
        $1::text,
        $2::text,
        $3::text
      )
      `,
      [null, null, null],
    );
    const sortedRows = result.rows.sort(
      (a, b) =>
        new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
    );
    const items = sortedRows.map((price) => {
      const citySlug = price.city_name.trim().replace(/\s+/g, "-");

      const productSlug = price.product_name.trim().replace(/\s+/g, "-");

      const url = `/city/${citySlug}/product/${productSlug}`;

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

router.get("/notify", async (_req: Request, res: Response) => {
  try {
    const HUB_URL = "https://pubsubhubbub.appspot.com/";
    const FEED_URL = `https://${BASE_URL}/api/sitemap/rss.xml`;

    const body = new URLSearchParams({
      "hub.mode": "publish",
      "hub.url": FEED_URL,
    });

    const response = await fetch(HUB_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: body.toString(),
    });

    if (!response.ok) {
      throw new Error(`WebSub notification failed: ${response.status}`);
    }

    return res.status(200).json({
      success: true,
      message: "WebSub notification sent successfully.",
    });
  } catch (error) {
    console.error("WebSub notification error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to send WebSub notification.",
    });
  }
});


export function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

export default router;
