import React from "react";

const Form = ({model, dispatch}) => {
  return(
    <form>
      <ReviewableInput
        inputParams={{type: "text"}}
        attrName="name"
        model={model}
        label="Restaurant name:"
        dispatch={dispatch}
      />
    </form>
  );
}

const basePath = ["ui", "formData"];

const ReviewableFieldset = ({model, attrName, handleCurrent, handleRemoved, dispatch}) => {
  <div>
    {
      
    }
  </div>
}

const ReviewableInput = ({model, attrName, inputParams, label, dispatch}) => {
  return(
    <div>
      <label>{ label }</label>
      {
        React.createElement(
          "input",
          _.assign(
            {
              value: _.get(model, basePath.concat("draft", attrName)),
              onChange: _.partial(changeInputValue, dispatch, "name")
            },
            inputParams
          )
        )
      }
      <div style={{color: "orange"}}>
        { `Was: ${_.get(model, basePath.concat("published", attrName))}`}
      </div>
    </div>
  );
}

const changeInputValue = (dispatch, attrName, event) => {
  dispatch({
    type: "CHANGE_INPUT_VALUE",
    proposed: event.target.value,
    attrName: attrName
  });
}

export default Form
