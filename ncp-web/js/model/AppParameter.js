import {ObservingObservable} from "./ObservingObserver.js";

export class AppParameter extends ObservingObservable {
  constructor(paramConfig) {
    super();
    this.id = paramConfig.id;
    this.name = paramConfig.name;
    this.value = paramConfig.value;
    this.suggest = paramConfig.suggest;
  }
}