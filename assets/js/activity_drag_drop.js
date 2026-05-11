import Sortable from "sortablejs";

let ActivityDragDrop = {
  mounted() {
    if (
      this.el.dataset.canEdit === undefined ||
      this.el.dataset.canEdit === "false"
    ) {
      return;
    }

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
        const canDrop = (to, dragEl) => {
          return (
            to.dataset.targetDay !== "outside" &&
            to.matches(selector) &&
            dragEl.matches(draggable)
          );
        };

        new Sortable(zone, {
          group: {
            name: groupName,
            put: (to, _from, dragEl) => canDrop(to.el || to, dragEl),
          },
          animation: 150,
          ghostClass: "hamster-drag-ghost",
          chosenClass: "hamster-drag-chosen",
          dragClass: "hamster-drag-item",
          draggable: draggable,
          onMove: (evt) => canDrop(evt.to, evt.dragged),
          onEnd: (evt) => {
            if (!canDrop(evt.to, evt.item) && evt.to !== evt.from) {
              return;
            }

            const entityId = evt.item.dataset[idKey];
            const newDayIndex = evt.to.dataset.targetDay;
            const oldDayIndex = evt.from.dataset.targetDay;
            const newIndex = evt.newIndex;

            if (newDayIndex !== oldDayIndex) {
              let parsedDayIndex = null;

              if (newDayIndex !== "unassigned") {
                parsedDayIndex = parseInt(newDayIndex);
              }

              this.pushEvent(moveEvent, {
                [idParam]: entityId,
                new_day_index: parsedDayIndex,
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

    setupSortable({
      selector: "[data-note-drop-zone]",
      draggable: ".draggable-note",
      groupName: "notes",
      idKey: "noteId",
      idParam: "note_id",
      moveEvent: "move_note",
      reorderEvent: "reorder_note",
    });
  },
};

export default { ActivityDragDrop };
