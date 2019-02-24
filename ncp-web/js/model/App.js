import {ObservableList} from "./ObservableList.js";
import {AppParameter} from "./AppParameter.js";
import {ObservingObservable} from "./ObservingObserver.js";

export class App extends ObservingObservable{
  constructor(cfg) {
    super();

    this.id = cfg.id;
    this.name = cfg.name;
    this.title = cfg.title;
    this.description = cfg.description;
    this.isActive = cfg.isActive;
    this.info = cfg.info;
    this.infotitle = cfg.infotitle;
    this.params = new ObservableList();
    cfg.params.forEach(param => { this.params.add(new AppParameter(param)); } );
    this.params.subscribe(this.notify);
  }

  static fromJson(jsonCfg) {
    let cfg = JSON.parse(jsonCfg);
    return new App(cfg);
  }

  equals(other) {
    return this === other || this.id === other.id;
  }
}