import {Observable} from "./Observable.js";

export class ObservingObservable extends Observable{

  notify(observable, childPropName, oldValue, newValue) {
    if( this._callbacks.length === 0)
      return;

    let propertyName;
    for(let property in this) {
      if( this.hasOwnProperty(property) && this[property] === observable ) {
        propertyName = property;
        break;
      }
    }

    if( propertyName === undefined )
      throw (propertyName + " not found in Observable!");

    this.onChanged(propertyName, undefined, this[propertyName])
  }
}