import initialSampleData from "initial_sample_data";

const rootReducer = (model = initialSampleData, action) => {
  return {
    app: model.app,
    ui: {
      formData: {
        active: active(model.ui.formData.draft, action),
        draft: model.ui.formData.draft,
        published: model.ui.formData.published
      }
    }
  }
}

const active = (model, action) => {
  switch(action.type){
  case "CHANGE_INPUT_VALUE":
    return _.assign(
      {},
      model,
      { [action.attrName]: action.proposed }
    )
  default:
    return model;
  }
}

export default rootReducer;
