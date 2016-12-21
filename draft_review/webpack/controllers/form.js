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
      <ReviewableSelect
        attrName="price_key"
        model={model}
        label="Price level"
        dispatch={dispatch}
      >
        {
          _.map(model.app.prices, (label, value) => {
            return(<option value={value} key={value}>{ label }</option>);
          })
        }
      </ReviewableSelect>
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

const ReviewableSelect = ({model, attrName, label, dispatch, children}) => {
  return(
    <div>
      <select value={ _.get(model, basePath.concat("draft", attrName)) }
        onChange={_.partial(changeInputValue, dispatch, attrName)}
      >
        { children }
      </select>
      <div style={{color: "orange"}}>
        {
          `Was: ${labelValue(attrName, _.get(model, basePath.concat("published", attrName)), model)}`
        }
      </div>
    </div>
  )
}

const labelValue = (attrName, value, model) => {
  switch(attrName) {
  case "price_key":
    return model.app.prices[value];
  }
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
              onChange: _.partial(changeInputValue, dispatch, attrName)
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
