import {Observable} from "./Observable.js";

export class ObservableList extends Observable {
  constructor(listenForItemChanges=false) {
    super();
    this._observables = [];
    this._listenForItemChanges = listenForItemChanges;
  }

  add(observable) {
    if( typeof(observable.subscribe) !== "function" )
      throw( "Only observables can be added to an observable list!" );

    this._observables.push(observable);
    observable.subscribe(this.notify);
    this.notify(this._observables.length - 1, null, observable);

  }

  remove(needle) {
    let index = needle;
    if( needle instanceof Observable )
      index = this._observables.indexOf(needle);
    if( index === -1 )
      throw( "The given object was not in found the ObservableList!" );

    let toDelete = this._observables[index];
    this._observables.splice(index, 1);
    toDelete.unsubscribe(this.notify);
    this.onChanged(-1, toDelete, null);
  }

  update(needle, observable) {
    let index = needle;
    if( needle instanceof Observable )
      index = this._observables.indexOf(needle);
    let toDelete = this._observables[index];
    toDelete.unsubscribe(this.notify);
    this._observables[index] = observable;
    this._observables[index].subscribe(this.notify);
    this.onChanged(index, toDelete, observable);
  }

  updateAll(observables) {
    for (let i = 0; i < observables.length; i++) {
      let index = this.find(observables[i]);
      if (index !== -1)
        this.update(index, observables[i]);
    }
  }

  find(observable) {
    for(let i = 0; i < this._observables.length; i++) {
      if( typeof(observable) === typeof(this._observables[i]) && this._observables[i].equals(observable) ) {
        return i;
      }
    }
  }

  notify(observable, paramName, oldValue, newValue) {
    if ( !this._listenForItemChanges )
      return;

    let index = this._observables.indexOf(observable);
    if( index === -1 )
      throw( "The given object was not in found the ObservableList!" );
    this.onChanged(index, undefined, observable);
  }

  forEach(fn) {
    this._observables.forEach(fn);
  }
}