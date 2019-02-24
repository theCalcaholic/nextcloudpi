import {AppListView} from "./view/AppListView.js";

let appListView = new AppListView();
let appListRoot = document.getElementById("ncp-options");
appListView.connect(appListRoot);