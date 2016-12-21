import React from "react";

const Form = ({model, dispatch}) => {
  const fieldsetData = _.assign(
    { baseChangePath: [] },
    model.ui.formData
  )

  return(
    <form>
      <div>
        <label>Restaurant name</label>
        <ReviewableInput
          type="text"
          fieldsetData={fieldsetData}
          dispatch={dispatch}
          attrName="name"
        />
        <PublishedValue
          fieldsetData={fieldsetData}
          attrName="name"
        />
      </div>
      <div>
        <ReviewableSelect
          type="text"
          fieldsetData={fieldsetData}
          dispatch={dispatch}
          attrName="price_key"
        >
          {
            _.map(model.app.prices, (label, value) => {
              return(<option value={value} key={value}>{label}</option>);
            })
          }
        </ReviewableSelect>
        <PublishedValue
          fieldsetData={fieldsetData}
          attrName="price_key"
          labelPrevious={(value) => model.app.prices[value]}
        />
      </div>
      <br/>
      <br/>
      <b>Menu Items</b>
      <ReviewableFieldsets
        fieldsetData={fieldsetData}
        attrName="menu_item_links"
        handleDrafted={DraftedMenuItem}
        handleRemoved={RemovedMenuItem}
        dispatch={dispatch}
        model={model}
      />
    </form>
  );
}

const ReviewableFieldsets = ({
  fieldsetData,
  attrName,
  handleDrafted,
  handleRemoved,
  dispatch,
  idAttr,
  model
}) => {
  const _idAttr = idAttr || "id";
  const drafts = fieldsetData.draft[attrName];
  const publisheds = fieldsetData.published[attrName];
  const actives = fieldsetData.active[attrName];

  const draftIds = drafts.map(_.property(_idAttr))

  return(
    <div>
      {
        actives.map((active, index) => {
          return React.createElement(
            handleDrafted,
            {
              attrName: attrName,
              dispatch: dispatch,
              index: index,
              key: index,
              model: model,
              fieldsetData: {
                draft: drafts.find((draft) => draft[_idAttr] === active[_idAttr]),
                published: publisheds.
                  find((published) => published[_idAttr] === active[_idAttr]),
                active: active,
                baseChangePath: fieldsetData.baseChangePath.concat(attrName, index)
              }
            }
          )
        })
      }
      <br/>
      <b>Removed</b>
      {
        publisheds.
          filter((published) => !_.includes(draftIds, published[_idAttr])).
          map((published, index) => {

          return React.createElement(
            handleRemoved,
            {
              attrName: attrName,
              dispatch: dispatch,
              key: index,
              fieldsetData: {
                published: published
              },
              model: model
            }
          );
        })
      }
    </div>
  );
}

const PublishedValue = ({fieldsetData, attrName, labelPrevious}) => {
  const _labelPrevious = labelPrevious || _.identity


  if (fieldsetData.published &&
    fieldsetData.published[attrName] !== fieldsetData.active[attrName]){
    return(
      <div style={{color: "orange"}}>
        { `Was: ${_labelPrevious(fieldsetData.published[attrName])}` }
      </div>
    )
  }
  else {
    return <span></span>;
  }
}

const ReviewableInput = (props) => {
  var {dispatch, fieldsetData, attrName} = props;

  return(
    <input
      value={fieldsetData.active[attrName]}
      onChange={
        _.partial(changeInputValue, dispatch, attrName, fieldsetData.basechangePath)
      }
      {..._.omit(props, ["dispatch", "fieldsetData", "attrName"])}
    />
  );
};

const ReviewableSelect = (props) => {
  var {dispatch, fieldsetData, attrName, children} = props;

  return(
    <select value={fieldsetData.draft[attrName]}
      onChange={
        _.partial(changeInputValue, dispatch, attrName, fieldsetData.basechangePath)
      }
      {..._.omit(props, ["dispatch", "fieldsetData", "attrName", "children"])}
    >
      { children }
    </select>
  );
};

const DraftedMenuItem = ({
  dispatch,
  fieldsetData,
  attrName,
  model
}) => {
  return(
    <div>
      <ReviewableSelect
        type="text"
        fieldsetData={fieldsetData}
        dispatch={dispatch}
        attrName="id"
      >
        {
          [<option key={""} value={""}></option>].concat(..._.map(model.app.menu_items, (record, id) => {
            return(<option key={id} value={id}>{record.name}</option>);
          }))
        }
      </ReviewableSelect>
      <div>
        <label>Preparation method</label>
        <ReviewableInput
          type="text"
          fieldsetData={fieldsetData}
          dispatch={dispatch}
          attrName="preparation_method"
        />
        <PublishedValue
          fieldsetData={fieldsetData}
          attrName="preparation_method"
        />
      </div>
      <RemoveFieldset fieldsetData={fieldsetData} dispatch={dispatch}/>
      <NewFieldsetAnnotation fieldsetData={fieldsetData}/>
      <br/>
    </div>
  );
};

const RemoveFieldset = () => {
  return <span></span>;
}

const NewFieldsetAnnotation = ({fieldsetData}) => {
  if (!fieldsetData.published){
    return(<div style={{color: "orange"}}>Added</div>);
  }
  else {
    return <span></span>;
  }
}

const RemovedMenuItem = ({fieldsetData, model}) => {
  return(
    <div style={{color: "orange"}}>
      <label>Menu Item: </label>
      <RemovedField
        fieldsetData={fieldsetData}
        attrName={"id"}
        labelPrevious={(value) => model.app.menu_items[value].name}
      />
      <br/>
      <label>Preparation Method: </label>
      <RemovedField
        fieldsetData={fieldsetData}
        attrName={"preparation_method"}
      />
      <hr/>
    </div>
  )
};

const RemovedField = ({fieldsetData, attrName, labelPrevious}) => {
  const _labelPrevious = labelPrevious || _.identity;

  return(
    <span style={{color: "orange"}}>
      { _labelPrevious(fieldsetData.published[attrName]) }
    </span>
  )
}

const changeInputValue = (dispatch, attrName, baseChangePath, event) => {
  dispatch({
    type: "CHANGE_INPUT_VALUE",
    proposed: event.target.value,
    baseChangePath: baseChangePath,
    attrName: attrName
  });
}

export default Form
