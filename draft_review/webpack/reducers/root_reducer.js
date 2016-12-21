import initialSampleData from "initial_sample_data";

const rootReducer = (model = initialSampleData, action) => {
  return {
    app: model.app,
    ui: {
      formData: {
        active: active(model.ui.formData.active, action),
        draft: model.ui.formData.draft,
        published: model.ui.formData.published
      }
    }
  }
}

const active = (model, action) => {
  switch(action.type){
  case "CHANGE_INPUT_VALUE":
    return updateAtPath(
      model,
      action.baseChangePath.concat(action.attrName),
      action.proposed
    );
  case "REMOVE_FIELDSET":
    const attrName = action.path[0];

    return _.assign(
      {},
      model,
      { [ attrName ] : model[attrName].filter((elem, index) => index !== action.path[1]) }
    )
  default:
    return model;
  }
}


const updateAtPath = (model, path, proposed) => {
  const cloned = _.clone(model)
  const attrName = path.shift();


  if (path.length === 0){
    cloned[attrName] = proposed;
  }
  else {
    cloned[attrName] = updateAtPath(cloned[attrName], path, proposed)
  }

  return cloned;
}

export default rootReducer;
