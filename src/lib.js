import Promise from 'bluebird';
import Request from 'request';
import debug   from 'debug';


let request = bluebird.promisifyAll(Request);

let Debug = (name) => {
  let d = debug(`wishapi:${name}`);
  
  if (process.memoryUsage) {
    d.mem = () => {
      let { rss, heapTotal, heapUsed } = process.memoryUsage();

      rss = Math.round(rss * 0.000001);
      heapTotal = Math.round(heapTotal * 0.000001);
      heapUsed = Math.round(heapUsed * 0.000001);

      d(`rss: ${rss} MB, heap: ${heapUsed}/${heapTotal} MB`);
    }
  }
  
  return d;
}


export { Promise, request, Debug };