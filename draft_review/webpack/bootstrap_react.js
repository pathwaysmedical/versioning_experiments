import Form from "controllers/form";
import Provider from "provider";
import createLogger from "redux-logger";
import { createStore, applyMiddleware } from "redux";
import ReactDOM from "react-dom";
import rootReducer from "reducers/root_reducer";
import React from "react";

const bootstrapReact = function() {
  const createStoreWithMiddleware = applyMiddleware(createLogger())(createStore);
  const store = createStoreWithMiddleware(rootReducer);

  document.addEventListener("DOMContentLoaded", function(event) {
    const renderFormTo = document.getElementById("react_root--template");
    if (renderFormTo){
      ReactDOM.render(
        <Provider childKlass={Form} store={store}/>,
        renderFormTo
      )
    }
  });
};

export default bootstrapReact;
