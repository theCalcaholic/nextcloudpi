import modelInstance from "../model/Model.js";

export class AppListView {
  constructor() {
    this.model = modelInstance;
    this.model.subscribe(this.notify);
    this.model.apps.subscribe(this.notify);
    this._rootContext = null;
    this._appNodes = [];
  }

  notify(observable, property, oldValue, newValue) {
    if( observable.is(this.model.apps) ) {

      if( oldValue === undefined ) // app configuration has changed, don't change app list
        return;

      if( oldValue !== null )
      this.addAppElement(property, newValue)
    }
  }

  addAppElement(app, position = -1) {
    let appElement = document.createElement("li");
    appElement.textContent = app.get("title") + (app.get("isActive") ? " ✓" : "");
    appElement.model = app;
    appElement.notify = (observable, property, oldValue, newValue) => {
      if( property === "title" || property === "active" )
        appElement.innerText = app.get("title") + (app.get("isActive") ? " ✓" : "");
    };
    app.subscribe(appElement.notify);
    this._rootContext.appendChild(appElement);
  }

  removeAppElement(item) {
    let elem;
    if( item.tagName !== undefined )
      elem = item;
    else if( item === -1)
      elem = this._rootContext.lastChild;
    else
      elem = this._rootContext.children.item(item);
    console.log(elem);
    if( elem.notify !== undefined && elem.model !== undefined )
      elem.model.unsubscribe(elem.notify);
    this._rootContext.removeChild(elem);
  }

  connect(domElement) {
    if( domElement.nodeName !== 'UL' && domElement.nodeName !== 'OL' )
      throw ("Root context element tag must be one of ['UL', 'OL'], was '" + domElement.nodeName + "'!");
    this._rootContext = domElement;
    console.log("element count: " + this._rootContext.children.length);
    while( this._rootContext.hasChildNodes() ) {
      console.log("removing element");
      this.removeAppElement(-1);
    }
    this.model.apps.forEach(this.addAppElement.bind(this));
  }
}