import React from "react";


const PreviousValue = (labeledPrevious) => {
  <div style={{color: "orange"}}>
    { `Was: ${labeledPrevious}`}
  </div>
}


const Form = ({model, dispatch}) => {
  const draft = model.ui.formData.draft
  const published = model.ui.formData.published

  return(
    <form>
      <div>
        <label>Restaurant name</label>
        <input
          type="text"
          value={draft.name}
          onChange={_.partial(changeInputValue, dispatch, attrName)}
        />
        <PreviousValue
          labeledPrevious={published.name}
        />
      </div>
      <div>
        <select value={draft.price_key}
          onChange={_.partial(changeInputValue, dispatch, "price_key")}
        >
          {
            _.map(model.app.prices, (label, value) => {
              return(<option value={value}>{label}</option>);
            })
          }
        </select>
        <PreviousValue
          labeledPrevious={model.app.prices[published.price_key]}
        />
      </div>
      <b>Menu Items</b>
      <ReviewableFieldsets
        model={model}
        attrName="menu_item_links"
        handleCurrent={CurrentMenuItem}
        handleRemoved={RemovedMenuItem}
        dispatch={dispatch}
      />
    </form>
  );
}

const BasePath = ["ui", "formData"];

const ReviewableFieldsets = ({model, attrName, handleCurrent, handleRemoved, dispatch}) => {
  const drafts = _.get(model, BasePath.concat("draft", attrName));
  const publisheds = _.get(model, BasePath.concat("published", attrName));
  const draftIds = drafts.map(_.property("id"))

  return(
    <div>
      {
        drafts.map((draft, index) => {
          return React.createElement(
            handleCurrent,
            {
              model: model,
              attrName: attrName,
              dispatch: dispatch,
              draft: draft,
              index: index,
              key: index,
              published: publisheds.find((published) => published.id === draft.id)
            }
          )
        })
      }
      {
        publisheds.filter((published) => !_.includes(draftIds, published.id)).map((published) => {
          return React.createElement(
            handleCurrent,
            {
              model: model,
              attrName: attrName,
              dispatch: dispatch,
              index: index,
              key: index,
              published: published
            }
          );
        })
      }
    </div>
  );
}

const CurrentMenuItem = ({
  model,
  dispatch,
  draft,
  published
}) => {
  return(
    <div>
      <select value={draft.id}
        onChange={_.partial(changeAssociatedId, dispatch, "menu_item")}
      >
        {
          _.map(model.app.menu_items, (id, record) => {
            return(<option key={id} value={id}>{label}</option>);
          }).unshift(<option key={""} value={""}></option>)
        }
      </select>
      
    </div>
  );
}

const changeAssociatedId = () => {

}

// constraint on adding new fields -- no dupes
// constraint on changing the identifying field -- no dupes

// const ReviewableSelect = ({model, attrName, label, dispatch, children}) => {
//   return(
//     <div>
//       <select value={ _.get(model, BasePath.concat("draft", attrName)) }
//         onChange={_.partial(changeInputValue, dispatch, attrName)}
//       >
//         { children }
//       </select>
//       <div style={{color: "orange"}}>
//         {
//           `Was: ${labelValue(attrName, _.get(model, BasePath.concat("published", attrName)), model)}`
//         }
//       </div>
//     </div>
//   )
// }
// const ReviewableInput = ({model, attrName, inputParams, label, dispatch}) => {
//   return(
//     <div>
//       <label>{ label }</label>
//       {
//         React.createElement(
//           "input",
//           _.assign(
//             {
//               value: _.get(model, BasePath.concat("draft", attrName)),
//               onChange: _.partial(changeInputValue, dispatch, attrName)
//             },
//             inputParams
//           )
//         )
//       }
//       <div style={{color: "orange"}}>
//         { `Was: ${_.get(model, BasePath.concat("published", attrName))}`}
//       </div>
//     </div>
//   );
// }

const changeInputValue = (dispatch, attrName, event) => {
  dispatch({
    type: "CHANGE_INPUT_VALUE",
    proposed: event.target.value,
    attrName: attrName
  });
}

export default Form
