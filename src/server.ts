import {PORT,corsUrl,environment} from './config';
import express , {Request, Response} from 'express';
import router from './routes/router';
import cors from 'cors';
import './database';
import path from 'path'
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { NotFoundError } from './core/ApiError';
const app = express();
app.use(helmet()); 
app.use(express.json());
app.get("/favicon.ico", (_req, res) => {
    res.status(204).end();
});
app.use(cors({origin:corsUrl,optionsSuccessStatus:200,credentials:true}));
console.clear();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
//#region Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 1000, 
  standardHeaders: true, 
  legacyHeaders: false, 
  message: 
  { message: "Too many requests, please try again later." },
});
//#endregion
app.use('/api', limiter);
app.use('/api', router);
// #region Serve static files
app.get('/', (req, res, next) => {
    const viewName = req.path === '/' ? 'index'
        : req.path.substring(1);
        console.log("View:", viewName);
    res.render(viewName);
});
// #endregion



app.use((req: Request , res :Response, next :Function) => next(new NotFoundError()));
//#region Error Handling Middleware
app.use((err:any, req:any, res:any, next:any) => {
  const status = res.statusCode && res.statusCode !== 200? res.statusCode: 500;
  console.log(err,"--- Error Middleware ---");
  if (environment === "production") {
    res.status(status).json({
      message: err.message,
    });
  } else {
    res.status(status).json({
      message: err.message,
      stack: err.stack
    });
  }
});
//#endregion

app.listen(PORT , 
  ()=>{
    console.log(`\n\x1b[1;32m➜  Server:\x1b[0m is up and running on:\x1b[34m http://localhost:${PORT}/ \x1b[0m  `);

  });
  
