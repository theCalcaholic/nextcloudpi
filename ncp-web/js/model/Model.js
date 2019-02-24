import {ObservableList} from "./ObservableList.js";
import {App} from "../model/App.js";
import {Observable} from "./Observable.js";

class Model extends Observable {
  constructor() {
    super();
    this.apps = new ObservableList();
    this.activeApp = -1;
  }
}

let instance = new Model();

let appCfg = `{
  "id": "test-app",
  "name": "Test App",
  "title": "Test App Title",
  "description": "Test App Description",
  "info": "Test App Info",
  "infotitle": "Test App Info Title",
  "params": [
    {
      "id": "USER",
      "name": "User",
      "value": "ncp",
      "suggest": "ncp"
    }
  ]
}`;

instance.apps.add(App.fromJson(appCfg));

export default instance;