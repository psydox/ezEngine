enum LocomotionState
{
    Walking = 0,
    Crouching = 1,
    Falling = 2,
    Rolling = 3,
}

class AlAnimScript : ezAngelScriptClass
{
    private LocomotionState m_LocState = LocomotionState::Walking;

    void Update()
    {
        ezLocalBlackboardComponent@ bb;
        if (!GetOwner().TryGetComponentOfBaseType(@bb))
            return;

        ezInputComponent@ input;
        if (!GetOwner().TryGetComponentOfBaseType(@input))
            return;

        ezJoltDefaultCharacterComponent@ char;
        if (!GetOwner().TryGetComponentOfBaseType(@char))
            return;
        
        float fwd = input.GetCurrentInputState("move_forwards", false);
        fwd -= input.GetCurrentInputState("move_backwards", false);
        bb.SetEntryValue("Walk-Fwd", fwd);

        const float moveRight = input.GetCurrentInputState("move_right", false);
        const float moveLeft = input.GetCurrentInputState("move_left", false);
        bb.SetEntryValue("Walk-LR", moveRight - moveLeft);

        if (m_LocState == LocomotionState::Walking || m_LocState == LocomotionState::Crouching)
        {
            if (input.GetCurrentInputState("crouch", true) > 0)
            {
                m_LocState = (m_LocState == LocomotionState::Walking) ? LocomotionState::Crouching : LocomotionState::Walking;
            }
        }

        if (m_LocState != LocomotionState::Rolling && char.IsInAir())
        {
            m_LocState = LocomotionState::Falling;
        }
        else if (m_LocState == LocomotionState::Falling)
        {
            m_LocState = LocomotionState::Walking;
        }

        if ((m_LocState == LocomotionState::Walking) && input.GetCurrentInputState("jump", true) > 0)
        {
            m_LocState = LocomotionState::Rolling;

            if (moveRight > 0.5)
                bb.SetEntryValue("Roll-Action", 2); // roll right
            else if (moveLeft > 0.5)
                bb.SetEntryValue("Roll-Action", 1); // roll left
            else
                bb.SetEntryValue("Roll-Action", 0); // forwards
        }

        // rotation
        {
            float turnLR = input.GetCurrentInputState("turn_right", false);
            turnLR -= input.GetCurrentInputState("turn_left", false);

            ezQuat rotLR = GetOwner().GetLocalRotation();
            ezQuat toRot = ezQuat::MakeFromAxisAndAngle(ezVec3(0, 0, 1), ezAngle::MakeFromDegree(turnLR * 50));
            rotLR = toRot * rotLR;

            GetOwner().SetLocalRotation(rotLR);
        }

        int stateFight = (input.GetCurrentInputState("stance_fight", false) > 0) ? 1 : 0;
        bb.SetEntryValue("Fighting-State", stateFight);

        if (stateFight == 0)
        {
            if (input.GetCurrentInputState("interact2", true) > 0)
            {
                bb.SetEntryValue("Hit-Reaction-Play", true);
            }
        }
        else if (stateFight == 1)
        {
            if (input.GetCurrentInputState("shoot", true) > 0)
            {
                bb.SetEntryValue("Fight_Action", 1);
            }
            else if (input.GetCurrentInputState("interact", true) > 0)
            {
                bb.SetEntryValue("Fight_Action", 2);
            }
            else if (input.GetCurrentInputState("interact2", true) > 0)
            {
                bb.SetEntryValue("Fight_Action", 3);
            }
        }

        bb.SetEntryValue("Locomotion-State", int(m_LocState));
    }

    void OnMsgInput(ezMsgInputActionTriggered@ msg)
    {
    }

    void OnMsgGeneric(ezMsgGenericEvent@ msg)
    {
        if (msg.Message == "Roll-Finished")
        {
            m_LocState = LocomotionState::Walking;
        }
    }

    void OnMsgDamage(ezMsgDamage@ msg)
    {
        ezLog::Info("Damage! {}", msg.Damage);

        ezLocalBlackboardComponent@ bb;
        if (!GetOwner().TryGetComponentOfBaseType(@bb))
            return;

        bb.SetEntryValue("Hit-Reaction-Play", true);
    }
}
