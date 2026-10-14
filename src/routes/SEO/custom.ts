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
    const type = _req.params.type;

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
        .sort((a, b) => a.city!.name.localeCompare(b.city!.name, "ar"));

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
function getImgAndSy(url: string) {
  return `<!-- صورة القناة -->
  <image>
  <url>${url}/favicons/favicon-32x32.png</url>
  <title>أسعار اليمن</title>
  <link>${url}</link>
  <width>144</width>
  <height>144</height>
  <description>شعار منصة أسعار اليمن</description>
  </image>
  
  <!-- معلومات التحديث الدوري -->
  <sy:updatePeriod>hourly</sy:updatePeriod>
  <sy:updateFrequency>1</sy:updateFrequency> 
  `;
}

export default router;

router.get("/test/:type", async (_req: Request, res: Response) => {
  try {
        const sender = _req.query.sender as string;
    const type = _req.params.type;

    const MAP_URL = `https://${sender || BASE_URL}`;
    const HUB_URL = "https://pubsubhubbub.appspot.com/";
    const FEED_URL = `${MAP_URL}/sitemap/custom/test/${type}?sender=${sender}`;

    const result = await pool.query(`
      SELECT id, name, slug
      FROM cities
      WHERE is_active = true
      ORDER BY name ASC
    `);

    const now = new Date().toUTCString();

    const items = result.rows.map((city) => {
      const url =
        `${MAP_URL}/${encodeURIComponent(city.slug)}`;

      return {
        title: `أسعار المنتجات في ${city.name}`,
        url,
        description:
          `تعرّف على أسعار المنتجات والسلع في ${city.name}، ` +
          `وتابع أحدث الأسعار والتحديثات المتاحة.`,
        category: "أسعار المدن",
        pubDate: now,
      };
    });

    // إزالة الروابط المكررة
const escapeCdata = (value: string) =>
  value.replace(/]]>/g, "]]]]><![CDATA[>");

const uniqueItems = Array.from(
  new Map(items.map((item) => [item.url, item])).values(),
);

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss
    version="2.0"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:content="http://purl.org/rss/1.0/modules/content/"
    xmlns:media="http://search.yahoo.com/mrss/"
    xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
    xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
    xmlns:georss="http://www.georss.org/georss"
    xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule"
>
  <channel>
    <title>أسعار اليمن | أسعار المنتجات والسلع</title>
    <link>${escapeXml(MAP_URL)}/</link>
    <description>${escapeXml(
      "تابع أحدث أسعار المنتجات والسلع في اليمن حسب المدينة.",
    )}</description>
    <language>ar</language>
    <generator>Markets YE RSS Generator</generator>
    <docs>https://www.rssboard.org/rss-specification</docs>
    <pubDate>${now}</pubDate>
    <lastBuildDate>${now}</lastBuildDate>
    <ttl>30</ttl>

    <atom:link
      href="${escapeXml(FEED_URL)}"
      rel="self"
      type="application/rss+xml"
    />

    ${getImgAndSy(MAP_URL)}

    ${uniqueItems
      .map(({ title, url, description, category, pubDate }) => {
        const contentHtml = `
          <article dir="rtl" lang="ar">
            <h2>${escapeXml(title)}</h2>
            <p>${escapeXml(description)}</p>
            <p>التصنيف: ${escapeXml(category)}</p>
            <p>
              <a href="${escapeXml(url)}">عرض تفاصيل الأسعار</a>
            </p>
          </article>
        `;

        return `
    <item>
      <title>${escapeXml(title)}</title>
      <link>${escapeXml(url)}</link>
      <guid isPermaLink="true">${escapeXml(url)}</guid>
      <description>${escapeXml(description)}</description>
      <category><![CDATA[${escapeCdata(category)}]]></category>
      <dc:creator><![CDATA[فريق أسعار اليمن]]></dc:creator>
      <dc:language>ar</dc:language>
      <pubDate>${escapeXml(pubDate)}</pubDate>
      <content:encoded><![CDATA[${escapeCdata(contentHtml)}]]></content:encoded>
    </item>`;
      })
      .join("")}

  </channel>
</rss>`;



    res
      .status(200)
      .set({
        "Content-Type": "application/rss+xml; charset=utf-8",
        "Cache-Control": "public, max-age=300, stale-while-revalidate=600",
      })
      .send(xml);
  } catch (error) {
    console.error("RSS error:", error);
    res.status(500).send("Failed to generate RSS");
  }
});


