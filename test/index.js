import { assert }   from './helpers';
import { Merchant } from '../lib';


describe('Merchant', () => {
  it('should run in sandbox when test', () => {
    let merchant = new Merchant({ sandbox: true });
    assert.equal(merchant.baseUrl, 'https://sandbox.merchant.wish.com/v1');
  });
});