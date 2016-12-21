const initialSampleData = {
  ui: {
    formData: {
      draft: {
        name: "Au Pied de Cochon",
        price_key: 3,
        has_takeout: false,
        menu_item_links: {
          3: { preparation_method: "Grilled" },
          2: { preparation_method: "Barbecued" }
        }
      },
      published: {
        name: "Au Pied Cochon typo",
        price_key: 1,
        has_takeout: true,
        menu_item_links: {
          3: { preparation_method: "Braised" },
          5: { preparation_method: "Seared" }
        }
      }
    }
  },
  app: {
    menu_items: {
      1: { id: 1, name: "Chicken" },
      2: { id: 2, name: "Beef" },
      3: { id: 3, name: "Pork" },
      4: { id: 4, name: "Carrots" },
      5: { id: 5, name: "Potatos"}
    }
  }
};

export default initialSampleData;
