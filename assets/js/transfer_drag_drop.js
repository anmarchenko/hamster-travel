import Sortable from "sortablejs";

let TransferDragDrop = {
  mounted() {
    // Get all transfer drop zones that can accept drops
    const transferDropZones = this.el.querySelectorAll(
      "[data-transfer-drop-zone]",
    );

    transferDropZones.forEach((zone) => {
      const isOutsideZone = zone.dataset.targetDay === "outside";
      
      new Sortable(zone, {
        group: {
          name: "transfers",
          put: !isOutsideZone // Prevent dropping into outside zone
        },
        sort: false, // Disable sorting within the same zone
        animation: 150,
        ghostClass: "hamster-drag-ghost",
        chosenClass: "hamster-drag-chosen",
        dragClass: "hamster-drag-item",
        draggable: ".draggable-transfer",
        onEnd: (evt) => {
          const transferId = evt.item.dataset.transferId;
          const newDayIndex = evt.to.dataset.targetDay;
          const oldDayIndex = evt.from.dataset.targetDay;

          // Only send event if actually moved to different day
          if (newDayIndex !== oldDayIndex) {
            this.pushEvent("move_transfer", {
              transfer_id: transferId,
              new_day_index: parseInt(newDayIndex),
              old_day_index: parseInt(oldDayIndex),
            });
          }
        },
      });
    });
  },
};

export default { TransferDragDrop };
