import Sortable from "sortablejs";

let ActivityDragDrop = {
  mounted() {
    const setupSortable = ({
      selector,
      draggable,
      groupName,
      idKey,
      idParam,
      moveEvent,
      reorderEvent,
    }) => {
      const dropZones = this.el.querySelectorAll(selector);

      dropZones.forEach((zone) => {
        const isOutsideZone = zone.dataset.targetDay === "outside";

        new Sortable(zone, {
          group: {
            name: groupName,
            put: !isOutsideZone,
          },
          animation: 150,
          ghostClass: "hamster-drag-ghost",
          chosenClass: "hamster-drag-chosen",
          dragClass: "hamster-drag-item",
          draggable: draggable,
          onEnd: (evt) => {
            const entityId = evt.item.dataset[idKey];
            const newDayIndex = evt.to.dataset.targetDay;
            const oldDayIndex = evt.from.dataset.targetDay;
            const newIndex = evt.newIndex;

            if (newDayIndex !== oldDayIndex) {
              this.pushEvent(moveEvent, {
                [idParam]: entityId,
                new_day_index: parseInt(newDayIndex),
                position: newIndex,
              });
            } else if (evt.newIndex !== evt.oldIndex) {
              this.pushEvent(reorderEvent, {
                [idParam]: entityId,
                position: newIndex,
              });
            }
          },
        });
      });
    };

    setupSortable({
      selector: "[data-activity-drop-zone]",
      draggable: ".draggable-activity",
      groupName: "activities",
      idKey: "activityId",
      idParam: "activity_id",
      moveEvent: "move_activity",
      reorderEvent: "reorder_activity",
    });

    setupSortable({
      selector: "[data-day-expense-drop-zone]",
      draggable: ".draggable-day-expense",
      groupName: "day-expenses",
      idKey: "dayExpenseId",
      idParam: "day_expense_id",
      moveEvent: "move_day_expense",
      reorderEvent: "reorder_day_expense",
    });
  },
};

export default { ActivityDragDrop };
