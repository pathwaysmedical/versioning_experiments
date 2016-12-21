import initialSampleData from "initial_sample_data";

const rootReducer = (model = initialSampleData, action) => {
  return {
    app: model.app,
    ui: {
      formData: {
        draft: draft(model.ui.formData.draft, action),
        published: model.ui.formData.published
      }
    }
  }
}

const draft = (model, action) => {
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
