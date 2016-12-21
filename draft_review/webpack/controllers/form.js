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
      <hr/>
      <b>Menu Items</b>
      <ReviewableFieldsets
        fieldsetData={fieldsetData}
        attrName="menu_item_links"
        handleDrafted={DraftedMenuItem}
        handleChanged={ChangedMenuItem}
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
  handleChanged,
  dispatch,
  idAttr,
  model
}) => {
  const _idAttr = idAttr || "id";
  const drafts = fieldsetData.draft[attrName];
  const publisheds = fieldsetData.published[attrName];
  const actives = fieldsetData.active[attrName];

  const draftIds = drafts.map(_.property(_idAttr))
  const publishedIds = publisheds.map(_.property(_idAttr))

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
      <hr/>
      <b>Removed</b>
      {
        publisheds.
          filter((published) => !_.includes(draftIds, published[_idAttr])).
          map((published, index) => {

          return React.createElement(
            handleChanged,
            {
              attrName: attrName,
              dispatch: dispatch,
              key: index,
              changedData: published,
              model: model
            }
          );
        })
      }
      <br/>
      <b>Added</b>
      {
        drafts.
          filter((draft) => !_.includes(publishedIds, draft[_idAttr])).
          map((draft, index) => {

          return React.createElement(
            handleChanged,
            {
              attrName: attrName,
              dispatch: dispatch,
              key: index,
              changedData: draft,
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
        _.partial(changeInputValue, dispatch, attrName, fieldsetData.baseChangePath)
      }
      {..._.omit(props, ["dispatch", "fieldsetData", "attrName"])}
    />
  );
};

const ReviewableSelect = (props) => {
  var {dispatch, fieldsetData, attrName, children} = props;

  return(
    <select value={fieldsetData.active[attrName]}
      onChange={
        _.partial(changeInputValue, dispatch, attrName, fieldsetData.baseChangePath)
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
      <br/>
    </div>
  );
};

const RemoveFieldset = ({fieldsetData, dispatch}) => {
  return(
    <div onClick={_.partial(removeFieldset, dispatch, fieldsetData.baseChangePath)}>
      Remove
    </div>
  );
}

const removeFieldset = (dispatch, path) => {
  dispatch({
    type: "REMOVE_FIELDSET",
    path: path
  });
};

const ChangedMenuItem = ({changedData, model}) => {
  return(
    <div>
      <div>{`Menu Item: ${model.app.menu_items[changedData.id].name}`}</div>
      <div>{`Preparation Method: ${changedData.preparation_method}`}</div>
      <hr/>
    </div>
  )
};


const changeInputValue = (dispatch, attrName, baseChangePath, event) => {
  dispatch({
    type: "CHANGE_INPUT_VALUE",
    proposed: event.target.value,
    baseChangePath: baseChangePath,
    attrName: attrName
  });
}

export default Form
