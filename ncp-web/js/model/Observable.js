export class Observable {
  constructor() {
    this._callbacks = [];
  }

  subscribe(callback) {
    this._callbacks.push(callback);
  }

  unsubscribe(callback) {
    let index = this._callbacks.indexOf(callback);
    if ( index === -1 )
      throw ( "No such callback!");
    this._callbacks.splice(index, 1);
  }

  onChanged(property, oldValue, newValue) {
    let observable = this;
    this._callbacks.forEach(fn => fn(observable, property, oldValue, newValue));

  }

  set(property, value) {
    if ( !this.hasOwnProperty(property) )
      throw("No such property: '" + property + "'!");
    this[property] = value;
  }

  get(property) {
    if ( !this.hasOwnProperty(property) )
      throw("No such property: '" + property + "'!");
    return this[property];
  }

  equals(other) {
    return this === other;
  }
}