import Promise from 'bluebird';
import request from 'request';
import Debug   from './debug';


const debug = new Debug('merchant');



class Merchant {
  constructor(options) {
    this.options = {
      apiKey: '',
      sandbox: false
    };
    
    Object.assign(this.options, options);
    
    if (this.options.sandbox) {
      this.baseUrl = 'https://sandbox.merchant.wish.com/v1';
    }
    else {
      this.baseUrl = 'https://merchant.wish.com/api/v1';
    }
  }
  
  authTest(callback) {
    request.getAsync('')
  }
}


export default Merchant;