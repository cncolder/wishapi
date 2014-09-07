process.env.NODE_ENV = 'test';
import chai           from 'chai';
import chaiAsPromised from 'chai-as-promised';


const { assert, expect } = chai;
const should = chai.should();
chai.use(chaiAsPromised);


export { assert, expect, should };