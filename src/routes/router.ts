import express from "express";
const router = express.Router();
import asyncHandler from "express-async-handler";

import auth from '../auth/jwt'
import priceRouter from "./Prices";
router.use("/prices", priceRouter);

import categoriesRouter from "./meta/categories";
import citiesRouter from "./meta/cities";
import productsRouter from "./meta/products";
import dashboardRouter from "./meta/dashboard";
import submissionRouter from "./meta/price-submissions";

router.use("/cities", citiesRouter);
router.use("/categories", categoriesRouter);
router.use("/products", productsRouter);
router.use("/dashboard", dashboardRouter);
router.use("/submission", submissionRouter);

import productsSearchRouter from "./meta/products-search";
router.use("/products-search", productsSearchRouter);
import sitemapRouter from "./SEO/sitemap";
router.use("/sitemap", sitemapRouter);



router.get('/check',auth,asyncHandler( async (req, res)=>{
  res.status(200).json({message:"Token is valid",status:"OK"})
}));
router.get('/health',asyncHandler( async (req, res)=>{
  res.status(200).json({message:"Server is healthy",status:"OK"
    ,cookies:req.cookies,query:req.query,body:req.body,params:req.params
    ,time:new Date().toISOString(),
    uptime: process.uptime()
  });
}));

// router.use(/.*/, auth,asyncHandler( async (req:any, res:any)=>{
//   console.log("Access to restricted path:", req.originalUrl);
//     res.status(200).json({message: 'Access to this path is not allowed',status:req.user,cookies:req.cookies,query:req.query,body:req.body,params:req.params});
// }));
export default router;
