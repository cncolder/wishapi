let { Set } = global;
delete global.Set;

import del     from 'del';

global.Set = Set;


export default del;