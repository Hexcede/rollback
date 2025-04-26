--!strict
--!native

export type Revert = () -> () | false

--- Initializes a stack of undo operations. Returns a function which performs all undo operations, a function which inserts an undo action, and a function which performs an action which returns an undo action.
local function Rollback(size: number?)
    -- Create a table containing all the functions to revert
    local reverts = if size then table.create(size) else {}

    --- Performs all undo operations
    local function rollback()
        local rollbackReverts = reverts

        -- Clear the reverts list
        reverts = if size then table.create(size) else {}

        -- Loop through the list of reverts backwards, undoing each one
        for i = #rollbackReverts, 1, -1 do
            rollbackReverts[i]()
        end
    end

    --- Inserts an undo operation onto the stack, and returns it for convenience
    --- @error NoYield -- It is not safe to yield inside of the revert function, do not do this
    local function addRollback(revert: Revert?): Revert?
        -- If the revert is falsy, return it
        if not revert then
            -- If the action failed explicitly, do full rollback
            if revert == false then
                rollback()
            end

            return revert
        end

        -- Ensure the callback is a function
        if type(revert) ~= "function" then
            error(`Expected function in addRollback, got {typeof(revert)} '{revert})'`, 2)
        end

        -- Add the callback
        table.insert(reverts, revert)

        return revert
    end

    --- Calls the action function with the given arguments, inserting the returned undo operation, and return it.
    --- @error NoYield -- It is not safe to yield inside of the revert function, do not do this
    local function performAction<T...>(action: (T...) -> Revert?, ...: T...)
        return addRollback(action(...))
    end

    return rollback, addRollback, performAction
end

return Rollback