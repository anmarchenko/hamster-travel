import Sortable from "sortablejs";

let ActivityDragDrop = {
  mounted() {
    // Get all activity drop zones that can accept drops
    const activityDropZones = this.el.querySelectorAll(
      "[data-activity-drop-zone]",
    );

    activityDropZones.forEach((zone) => {
      new Sortable(zone, {
        group: {
          name: "activities",
        },
        animation: 150,
        ghostClass: "hamster-drag-ghost",
        chosenClass: "hamster-drag-chosen",
        dragClass: "hamster-drag-item",
        draggable: ".draggable-activity",
        onEnd: (evt) => {
          const activityId = evt.item.dataset.activityId;
          const newDayIndex = evt.to.dataset.targetDay;
          const oldDayIndex = evt.from.dataset.targetDay;
          const newIndex = evt.newIndex;
          
          if (newDayIndex !== oldDayIndex) {
            // Moved to a different day
            this.pushEvent("move_activity", {
              activity_id: activityId,
              new_day_index: parseInt(newDayIndex),
              position: newIndex
            });
          } else if (evt.newIndex !== evt.oldIndex) {
            // Reordered within the same day
            this.pushEvent("reorder_activity", {
              activity_id: activityId,
              position: newIndex
            });
          }
        },
      });
    });
  },
};

export default { ActivityDragDrop };
