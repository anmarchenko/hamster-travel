import Sortable from "sortablejs";

let PackingDragDrop = {
  mounted() {
    // Get all list drop zones that can accept item drops
    const listDropZones = this.el.querySelectorAll("[data-packing-drop-zone]");

    listDropZones.forEach((zone) => {
      new Sortable(zone, {
        group: {
          name: "packing-items",
          put: true, // Allow dropping items into any list
        },
        sort: true, // Enable sorting within the same zone
        animation: 150,
        ghostClass: "hamster-drag-ghost",
        chosenClass: "hamster-drag-chosen",
        dragClass: "hamster-drag-item",
        draggable: ".draggable-item",
        onEnd: (evt) => {
          const itemId = evt.item.dataset.itemId;
          const newListId = evt.to.dataset.targetListId;
          const oldListId = evt.from.dataset.targetListId;
          const newPosition = evt.newIndex; // 1-based position for backend

          // Send event for both moving between lists and reordering within list
          if (newListId !== oldListId) {
            // Item moved to different list
            this.pushEvent("move_item_to_list", {
              item_id: itemId,
              new_list_id: newListId,
              old_list_id: oldListId,
              position: newPosition,
            });
          } else if (evt.newIndex !== evt.oldIndex) {
            // Item reordered within same list
            this.pushEvent("reorder_item", {
              item_id: itemId,
              position: newPosition,
            });
          }
        },
      });
    });
  },
};

export default { PackingDragDrop };
